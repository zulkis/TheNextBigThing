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

static CGFloat ITBPostsEstimatedCellHeight = 60.f;

@interface ITBPostsViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic) BOOL beganUpdates;

@property (nonatomic, weak) IBOutlet ITBTableView *tableView;

@property (nonatomic, strong) UIView *bottomLoadingIndicatorView;

@property (nonatomic, strong) ITBPostsDataSource *postsDataSource;

@property (nonatomic, strong) NSTimer *updatingrTimeForPostStartTimer;

@end

@implementation ITBPostsViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _postsDataSource = [ITBPostsDataSource new];
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
    [self.tableView.refreshControl addTarget:self action:@selector(_refreshControlWantsUpdate:) forControlEvents:UIControlEventValueChanged];
    
    [_postsDataSource prepareWork];
    
    
    self.postsDataSource.fetchedResultsController.delegate = self;
    weakify(self)
    self.postsDataSource.onDidEndPerformFetch = ^{
        strongify(self)
        [self.tableView reloadData];
    };
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.postsDataSource update];
    
    [self.tableView reloadData];
    
    [self _startUpdatingTimeForPostsStart];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self _stopUpdatingTimeForPostsStart];
}

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    
    [self.postsDataSource removeObserver:self forKeyPath:ITBUpdatingKeyPath];
    [self.postsDataSource removeObserver:self forKeyPath:ITBLoadingOneMoreKeyPath];
    
    [self.postsDataSource reset];
    
    [self _stopUpdatingTimeForPostsStart];
}

#pragma mark - Private

- (void)_refreshControlWantsUpdate:(UIRefreshControl *)refreshControl {
    [self.tableView.refreshControl beginRefreshing];
    [self.postsDataSource update];
}

- (void)_updateLoadingIndicatorWithValue:(BOOL)value {
    if (value) {
        [self.tableView.refreshControl beginRefreshing];
        if (self.tableView.contentOffset.y == 0) {
            
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void){
                
                self.tableView.contentOffset = CGPointMake(0, -self.tableView.refreshControl.frame.size.height);
                
            } completion:^(BOOL finished){
                
            }];
        }
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

- (void)_configureCell:(ITBPostTableViewCell *)cell withPost:(ITBPost *)post {
    cell.post = post;
}

- (void)_startUpdatingTimeForPostsStart {
    const NSTimeInterval timerTimeInterval = 10.f;
    self.updatingrTimeForPostStartTimer = [NSTimer scheduledTimerWithTimeInterval:timerTimeInterval
                                                                           target:self
                                                                         selector:@selector(_performTimeForPostsStartUpdate)
                                                                         userInfo:nil
                                                                          repeats:YES];
    [self.updatingrTimeForPostStartTimer fire];
}

- (void)_stopUpdatingTimeForPostsStart {
    [self.updatingrTimeForPostStartTimer invalidate];
    self.updatingrTimeForPostStartTimer = nil;
}

- (void)_performTimeForPostsStartUpdate {
    NSArray *visibleCells = [self.tableView visibleCells];
    NSArray *visibleIndexes = [self.tableView indexPathsForVisibleRows];
    int count = [visibleCells count];
    for (int i = 0; i < count; i ++) {
        NSIndexPath *ip = visibleIndexes[i];
        ITBPostTableViewCell *postCell = visibleCells[i];
        [postCell setPost:self.postsDataSource[ip]];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = NSStringFromClass([ITBPostTableViewCell class]);
    ITBPostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    ITBPost *post = self.postsDataSource[indexPath];
    [self _configureCell:cell withPost:post];
    
    return cell;
}

/*
 Increaasing performance since we could have a LOT of posts in DB
 */
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ITBPost *post = self.postsDataSource[indexPath];
    NSMutableDictionary *cachedHeights = nil;
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        cachedHeights = self.postsDataSource.cachedHeights;
    } else {
        cachedHeights = self.postsDataSource.horizontalCachedHeights;
    }
    
    if (cachedHeights[post.identifier]) {
        return [cachedHeights[post.identifier] floatValue];
    }
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static ITBPostTableViewCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [ITBPostTableViewCell new];
    });
    
    ITBPost *post = self.postsDataSource[indexPath];
    
    NSMutableDictionary *cachedHeights = nil;
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        cachedHeights = self.postsDataSource.cachedHeights;
    } else {
        cachedHeights = self.postsDataSource.horizontalCachedHeights;
    }
    
    if (!cachedHeights[post.identifier]) {
        [sizingCell updateConstraintsWithTableViewWidth:CGRectGetWidth(self.tableView.frame)];
        
        [self _configureCell:sizingCell withPost:post];
        
        CGFloat cellHeight = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height + 1;
        
        cachedHeights[post.identifier] = @(cellHeight);
    }
    
    return [cachedHeights[post.identifier] floatValue];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self _startUpdatingTimeForPostsStart];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.updatingrTimeForPostStartTimer) {
        [self _stopUpdatingTimeForPostsStart];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self _startUpdatingTimeForPostsStart];
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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
    self.beganUpdates = YES;
}

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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.beganUpdates) {
        [self.tableView endUpdates];
    }
}

@end
