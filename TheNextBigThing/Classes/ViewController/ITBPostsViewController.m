//
//  ITBPostsViewController.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBPostsViewController.h"
#import "ITBPostsDataSource.h"
#import "ITBStorageManager.h"

#import "ITBTableView.h"
#import "ITBPostTableViewCell.h"

#import "ITBPost+Extension.h"
#import "ITBStream.h"


static CGFloat ITBPostsEstimatedCellHeight = 60.f;
static NSTimeInterval ITBResetFeedTimeInterval = 600; // 10 Minutes

@interface ITBPostsViewController () <ITBPostsDataSourceViewModel, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic) BOOL beganUpdates;

@property (nonatomic, weak) IBOutlet ITBTableView *tableView;

@property (nonatomic, strong) UIView *bottomLoadingIndicatorView;

@property (nonatomic, strong) ITBPostsDataSource *postsDataSource;

@property (nonatomic, strong) NSTimer *updatingrTimeForPostStartTimer;

@property (nonatomic, strong) NSDate *backgroundEnteringDate;

@property (nonatomic, strong) ITBStream *stream;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation ITBPostsViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self _createFetchedResultsController];
        
        _stream = [[ITBStream alloc] initWithStorage:[ITBStorageManager sharedInstance]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef DEBUG
    [self _addVersionLabel];
#endif
    
    self.postsDataSource = [ITBPostsDataSource new];
    self.postsDataSource.fetchedResultsController = _fetchedResultsController;
    self.postsDataSource.delegate = self;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self.postsDataSource;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ITBPostTableViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:NSStringFromClass([ITBPostTableViewCell class])];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.stream addObserver:self
                           forKeyPath:ITBUpdatingKeyPath
                              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                              context:nil];
    [self.stream addObserver:self
                           forKeyPath:ITBLoadingOneMoreKeyPath
                              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                              context:nil];
    
    [self.tableView.refreshControl addTarget:self action:@selector(_refreshControlWantsUpdate:) forControlEvents:UIControlEventValueChanged];
    
    self.postsDataSource.fetchedResultsController.delegate = self;
    
    [self _reloadStream];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self _startUpdatingTimeForPostsStart];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self _stopUpdatingTimeForPostsStart];
}

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.postsDataSource.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.stream removeObserver:self forKeyPath:ITBUpdatingKeyPath];
    [self.stream removeObserver:self forKeyPath:ITBLoadingOneMoreKeyPath];
    
    [self _stopUpdatingTimeForPostsStart];
}

#pragma mark - Private

- (void)_applicationDidBecomeActive:(NSNotification *)note {
    if (self.backgroundEnteringDate) {
        NSTimeInterval lastTime = [self.backgroundEnteringDate timeIntervalSince1970];
        NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
        
        NSTimeInterval diff = (nowTime - lastTime);
        
        if (diff >= ITBResetFeedTimeInterval) {
            [self.stream reloadData];
        }
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    self.backgroundEnteringDate = [NSDate date];
}

- (void)_addVersionLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
    label.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[label]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"label":label}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"label":label}]];
    
    label.text = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
}

- (void)_createFetchedResultsController
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[ITBPost entityName]];
    fetchRequest.fetchBatchSize = 10;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:[ITBStorageManager sharedInstance].mainThreadContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:@"cacheName"];
}

- (void)_refreshControlWantsUpdate:(UIRefreshControl *)refreshControl {
    [self.tableView.refreshControl beginRefreshing];
    [self.stream loadNewer];
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

- (void)_startUpdatingTimeForPostsStart {
    const NSTimeInterval timerTimeInterval = 10.f;
    if (!self.updatingrTimeForPostStartTimer) {
        self.updatingrTimeForPostStartTimer = [NSTimer scheduledTimerWithTimeInterval:timerTimeInterval
                                                                               target:self
                                                                             selector:@selector(_performTimeForPostsStartUpdate)
                                                                             userInfo:nil
                                                                              repeats:YES];
        [self.updatingrTimeForPostStartTimer fire];
    }
}

- (void)_stopUpdatingTimeForPostsStart {
    [self.updatingrTimeForPostStartTimer invalidate];
    self.updatingrTimeForPostStartTimer = nil;
}

- (void)_performTimeForPostsStartUpdate {
    NSArray *visibleCells = [self.tableView visibleCells];
    int count = [visibleCells count];
    for (int i = 0; i < count; i ++) {
        ITBPostTableViewCell *postCell = visibleCells[i];
        [postCell updateTimeLabel];
    }
}

#pragma mark - ITBPostsDataSourceViewModel

- (CGFloat)widthForCellsForDataSource:(ITBPostsDataSource *)dataSource {
    return CGRectGetWidth(self.tableView.frame);
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.postsDataSource respondsToSelector:_cmd]) {
        return [self.postsDataSource tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
    }
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.postsDataSource respondsToSelector:_cmd]) {
        return [self.postsDataSource tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    return 100;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(ITBPostTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    static const NSUInteger ITBCellBottomTriggerCount = 5;
    if (([self.postsDataSource numberRowsInSection:0] > ITBCellBottomTriggerCount &&
         indexPath.row >= ([self.postsDataSource numberRowsInSection:0] - ITBCellBottomTriggerCount)) ||
        [self.postsDataSource numberRowsInSection:0] < ITBCellBottomTriggerCount) {
        if (self.stream.couldLoadMore &&
            !self.stream.loadingOneMorePage &&
            !self.stream.updating) {
            [self.stream loadOlder];
        }
    }
}

#pragma mark - Fetch Posts

- (void)_reloadStream {
    [self.stream reloadData];
    [self _showFeedsSavedLocally];
}

- (void)_showFeedsSavedLocally {
    NSError *error = nil;
    BOOL successfullyFetchedNewsFromDatabase = [self.fetchedResultsController performFetch:&error];
    
    if (successfullyFetchedNewsFromDatabase == NO) {
        NSLog(@"Error occurred while fetching feeds from database: %@", error.localizedDescription);
    }
    
    [self.tableView reloadData];
}



#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self _startUpdatingTimeForPostsStart];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self _stopUpdatingTimeForPostsStart];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self _startUpdatingTimeForPostsStart];
    }
}

#pragma mark - UIViewControllerRotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self _stopUpdatingTimeForPostsStart];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self _startUpdatingTimeForPostsStart];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.stream) {
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
