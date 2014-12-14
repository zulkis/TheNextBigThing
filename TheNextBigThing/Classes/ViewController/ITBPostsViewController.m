//
//  ITBPostsViewController.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBPostsViewController.h"
#import "ITBPostsDataSource.h"

#import "ITBTableView.h"
#import "ITBPostTableViewCell.h"
#import "ITBPost.h"

static NSInteger ITBPostsSectionLoadingMoreIndicator = 1;
static CGFloat ITBPostsEstimatedCellHeight = 60.f;

@interface ITBPostsViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic) BOOL beganUpdates;

@property (nonatomic, weak) IBOutlet ITBTableView *tableView;

@property (nonatomic, strong) UIView *bottomLoadingIndicatorView;

@property (nonatomic, strong) ITBPostsDataSource *postsDataSource;

@end

@implementation ITBPostsViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _postsDataSource = [ITBPostsDataSource new];
        [_postsDataSource prepareWork];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ITBPostTableViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:NSStringFromClass([ITBPostTableViewCell class])];
    
    [self.postsDataSource addObserver:self
                      forKeyPath:ITBUpdatingKeyPath
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                         context:nil];
    [self.postsDataSource addObserver:self
                      forKeyPath:ITBLoadingOneMoreKeyPath
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                         context:nil];
    
    [self.tableView.refreshControl addTarget:self action:@selector(refreshControlWantsUpdate:) forControlEvents:UIControlEventValueChanged];


    self.postsDataSource.fetchedResultsController.delegate = self;
    weakify(self)
    self.postsDataSource.onDidEndPerformFetch = ^{
        strongify(self)
        [self.tableView reloadData];
    };
//    [self.postsDataSource update];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // initial cells did not look autoresizable' without that
    [self.tableView reloadData];
}

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    
    [self.postsDataSource removeObserver:self forKeyPath:ITBUpdatingKeyPath];
    [self.postsDataSource removeObserver:self forKeyPath:ITBLoadingOneMoreKeyPath];
    
    [self.postsDataSource reset];
}

#pragma mark - Private

- (void)refreshControlWantsUpdate:(UIRefreshControl *)refreshControl {
    [self.tableView.refreshControl beginRefreshing];
    [self.postsDataSource update];
}

- (void)_updateLoadingIndicatorWithValue:(BOOL)value {
    if (value) {
        [self.tableView.refreshControl beginRefreshing];
    } else {
        [self.tableView.refreshControl endRefreshing];
    }
}

- (void)_updateLoadingMoreIndicatorWithValue:(BOOL)value {
    if (value) {
        [self _showBottomLoadingIndicator];
    } else {
        [self _hideBottomLoadingIndicator];
    }
}

- (UIView *)bottomLoadingIndicatorView {
    if (!_bottomLoadingIndicatorView) {
        _bottomLoadingIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), ITBPostsEstimatedCellHeight)];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.center = _bottomLoadingIndicatorView.center;
        [activityIndicator startAnimating];
        [_bottomLoadingIndicatorView addSubview:activityIndicator];
    }
    return _bottomLoadingIndicatorView;
}

- (void)_showBottomLoadingIndicator {
    self.tableView.tableFooterView = self.bottomLoadingIndicatorView;
}

- (void)_hideBottomLoadingIndicator {
    self.tableView.tableFooterView = nil;
}

- (void)_configureCell:(ITBPostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ITBPost *post = self.postsDataSource[indexPath];
    
    cell.post = post;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = NSStringFromClass([ITBPostTableViewCell class]);
    ITBPostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    [self _configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static ITBPostTableViewCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [ITBPostTableViewCell new];
    });
    
    NSNumber *ix = @(indexPath.row);
    
    if (!self.postsDataSource.cachedHeights[ix]) {
        [sizingCell setNeedsUpdateConstraints];
        [self _configureCell:sizingCell atIndexPath:indexPath];
        
        CGFloat cellHeight = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height + 1;
        
        self.postsDataSource.cachedHeights[ix] = @(cellHeight);
    }

    return [self.postsDataSource.cachedHeights[ix] floatValue];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.postsDataSource numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.postsDataSource numberRowsInSection:section];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(ITBPostTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.postsDataSource.canBeLoadMore && // we can load one more page
        (indexPath.row >= ([self.postsDataSource numberRowsInSection:0] - 5) || [self.postsDataSource numberRowsInSection:0] < 5) && // we are in the end of list
        !self.postsDataSource.loadingOneMorePage &&
        !self.postsDataSource.updating) { // we are not loading

        [self.postsDataSource loadOneMorePage];
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.postsDataSource) {
        if ([keyPath isEqualToString:ITBUpdatingKeyPath]) {
            NSNumber *newNumber = change[NSKeyValueChangeNewKey];
            SAFE_MAIN_THREAD_EXECUTION({
                [self _updateLoadingIndicatorWithValue:newNumber.boolValue];
            });
        }
        
        if ([keyPath isEqualToString:ITBLoadingOneMoreKeyPath]) {
            NSNumber *oldNumber = change[NSKeyValueChangeOldKey];
            NSNumber *newNumber = change[NSKeyValueChangeNewKey];
            if ([oldNumber isEqualToNumber:newNumber] == NO) {
                SAFE_MAIN_THREAD_EXECUTION({
                    [self _updateLoadingMoreIndicatorWithValue:newNumber.boolValue];
                });
            }
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

//#pragma mark - NSFetchedResultsControllerDelegate
//
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
    self.beganUpdates = YES;
}
//
- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}
//
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.beganUpdates) {
        [self.tableView endUpdates];
    }
//    [self.tableView reloadData];
}

@end
