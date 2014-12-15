//
//  ITBPostsDataSource.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//


#import <Foundation/Foundation.h>

@class ITBPostsDataSource;

@protocol ITBPostsDataSourceViewModel <NSObject>

@required
- (CGFloat)widthForCellsForDataSource:(ITBPostsDataSource *)dataSource;

@end

@interface ITBPostsDataSource : NSObject <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, weak) id<ITBPostsDataSourceViewModel> delegate;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberRowsInSection:(NSUInteger)section;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

// we can use CoreBaseDataSource[NSIndexPath]
- (id)objectForKeyedSubscript:(NSIndexPath *)indexPath;


@end
