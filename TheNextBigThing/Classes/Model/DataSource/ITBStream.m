//
//  ITBStream.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 15/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBStream.h"
#import "ITBStorageManager.h"
#import "ITBPostsFetcher.h"
#import "ITBPostsBuilder.h"
#import "ITBUnparsedPosts.h"

#import "ITBPost+Extension.h"


NSString * const ITBUpdatingKeyPath = @"updating";
NSString * const ITBLoadingOneMoreKeyPath = @"loadingOneMorePage";

@interface ITBStream ()

@property (nonatomic, assign, readwrite) BOOL updating;
@property (nonatomic, assign, readwrite) BOOL loadingOneMorePage;
@property (nonatomic, assign, readwrite) BOOL couldLoadMore;

@property (nonatomic, weak, readwrite) ITBStorageManager *storageManager;

@property (nonatomic, strong) ITBPostsFetcher *fetcher;
@property (nonatomic, strong) ITBPostsBuilder *builder;

@end

@implementation ITBStream

+ (BOOL)automaticallyNotifiesObserversOfLoadingOneMorePage {
    return YES;
}

- (instancetype)initWithStorage:(ITBStorageManager *)storage {
    self = [super init];
    if (self) {
        _couldLoadMore = YES;
        _loadingPageSize = 20;
        _storageManager = storage;
        
        _fetcher = [ITBPostsFetcher new];
        _builder = [[ITBPostsBuilder alloc] initWithStream:self];
    }
    return self;
}

- (void)loadNewer {
    if (_updating || _loadingOneMorePage) {
        // already updating
        return;
    }
    self.updating = YES;
    ITBPost *message = [ITBPost findWithHighestIdentifierInContext:self.storageManager.mainThreadContext];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    __block BOOL shouldUpdateCouldSaveFlag = YES;
    
    const NSInteger loadNewCount = 100;
    if (message) {
        shouldUpdateCouldSaveFlag = NO;
        params[@"since_id"] = message.identifier;
        params[@"count"] = @(-loadNewCount);
    } else {
        params[@"count"] = @(loadNewCount);
    }
    weakify(self)
    [_fetcher getPostsWithParams:params
                      completion:^(ITBUnparsedPosts *unparsedPosts, NSError *error) {
                          strongify(self)
                          if (shouldUpdateCouldSaveFlag) {
                              self.couldLoadMore = unparsedPosts.couldLoadMore;
                          }
                          [self.builder makePostsFromUnparsedPostsData:unparsedPosts completion:^(NSError *error) {
                              self.updating = NO;
                          }];
                      }];
}

- (void)loadOlder {
    if (_updating || _loadingOneMorePage) {
        // already updating
        return;
    }
    self.loadingOneMorePage = YES;
    
    ITBPost *message = [ITBPost findWithLowestIdentifierInContext:self.storageManager.mainThreadContext];
    NSDictionary *params = @{@"count":@(self.loadingPageSize), @"before_id":message.identifier};
    weakify(self)
    [_fetcher getPostsWithParams:params
                      completion:^(ITBUnparsedPosts *unparsedPosts, NSError *error) {
                          strongify(self)
                          self.couldLoadMore = unparsedPosts.couldLoadMore;
                          [self.builder makePostsFromUnparsedPostsData:unparsedPosts completion:^(NSError *error) {
                              self.loadingOneMorePage = NO;
                          }];
                      }];
}

- (void)reloadData {
    if (_updating || _loadingOneMorePage) {
        // already updating
        return;
    }

    [self _clearLoadedEntitiesWithCompletion:^(NSError *error) {
        [self loadNewer];
    }];
}

#pragma mark - Private

- (void)_clearLoadedEntitiesWithCompletion:(void(^)(NSError *error))completion {
    [self.storageManager saveDataSerialWithPrivateContextSupport:^(NSManagedObjectContext *context) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[ITBPost entityName]];
        NSError *executeError = nil;
        NSArray *existedObjects = [context executeFetchRequest:fetchRequest error:&executeError];
        for (NSManagedObject *object in existedObjects) {
            [object.managedObjectContext deleteObject:object];
        }
    } completion:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

@end
