//
//  ITBStream.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 15/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITBStorageManager;

extern NSString * const ITBUpdatingKeyPath;
extern NSString * const ITBLoadingOneMoreKeyPath;

@interface ITBStream : NSObject

@property (nonatomic, weak, readonly) ITBStorageManager *storageManager;

// TODO: need to store it before updating in case of changing the page size
@property (nonatomic) NSInteger loadingPageSize; // Default: 20

@property (nonatomic, assign, readonly) BOOL updating;
@property (nonatomic, assign, readonly) BOOL loadingOneMorePage;
@property (nonatomic, assign, readonly) BOOL couldLoadMore;

- (instancetype)initWithStorage:(ITBStorageManager *)storage;

- (void)loadNewer;
- (void)loadOlder;

- (void)reloadData;

@end
