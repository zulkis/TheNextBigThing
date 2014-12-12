//
//  ITBPostsDataSource.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//


#import <Foundation/Foundation.h>


extern NSString * const ITBUpdatingKeyPath;
extern NSString * const ITBLoadingOneMoreKeyPath;

@interface ITBPostsDataSource : NSObject

- (void)prepareWork;
- (void)reset;

@property (nonatomic) NSUInteger loadingPageSize; // Default: 20

@property (nonatomic, assign, readonly) BOOL updating;
@property (nonatomic, assign, readonly) BOOL loadingOneMorePage;
@property (nonatomic, assign) BOOL canBeLoadMore;

@property (nonatomic, weak, readonly) NSURLSessionDataTask *updateDataTask;
@property (nonatomic, weak, readonly) NSURLSessionDataTask *loadOneMorePageDataTask;

@property (nonatomic, retain, readonly) NSArray *dataSourceArray;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberRowsInSection:(NSUInteger)section;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

// we can use CoreBaseDataSource[NSIndexPath]
- (id)objectForKeyedSubscript:(NSIndexPath *)indexPath;

- (void)loadOneMorePage;
- (void)update;

#pragma mark - Fetches from coreData

@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, copy) void(^onDidEndPerformFetch)();

- (void)performFetch;

@end
