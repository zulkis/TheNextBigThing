//
//  ITBPostsDataSource.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//


#import "ITBPostsDataSource.h"

#import "ITBBaseEntity+Extension.h"
#import "ITBPost+Extension.h"

#import "ITBStorageManager.h"

#import "ITBPostTableViewCell.h"

@interface ITBPostsDataSource ()

@property (nonatomic, strong) NSMutableDictionary *cachedHeights;
@property (nonatomic, strong) NSMutableDictionary *horizontalCachedHeights;

@end

@implementation ITBPostsDataSource

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _cachedHeights = [NSMutableDictionary new];
        _horizontalCachedHeights = [NSMutableDictionary new];
    }
    
    return self;
}

- (NSUInteger)numberOfSections
{
    return [[self.fetchedResultsController sections] count];
}

- (NSUInteger)numberRowsInSection:(NSUInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (id)objectForKeyedSubscript:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (void)dealloc {
    DBGLog(@"data source released");
}

#pragma mark - Private

- (void)_configureCell:(ITBPostTableViewCell *)cell withPost:(ITBPost *)post {
    cell.post = post;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = NSStringFromClass([ITBPostTableViewCell class]);
    ITBPostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    ITBPost *post = self[indexPath];
    [self _configureCell:cell withPost:post];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberRowsInSection:section];
}

#pragma mark - UITableViewDelegate

/*
 Increaasing performance since we could have a LOT of posts in DB
 */
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ITBPost *post = self[indexPath];
    NSMutableDictionary *cachedHeights = nil;
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        cachedHeights = self.cachedHeights;
    } else {
        cachedHeights = self.horizontalCachedHeights;
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
    
    ITBPost *post = self[indexPath];
    
    NSMutableDictionary *cachedHeights = nil;
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        cachedHeights = self.cachedHeights;
    } else {
        cachedHeights = self.horizontalCachedHeights;
    }
    
    if (!cachedHeights[post.identifier]) {
        [sizingCell updateConstraintsWithTableViewWidth:[self.delegate widthForCellsForDataSource:self]];
        
        [self _configureCell:sizingCell withPost:post];
        
        CGFloat cellHeight = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height + 1;
        
        cachedHeights[post.identifier] = @(cellHeight);
    }
    
    return [cachedHeights[post.identifier] floatValue];
}

@end