//
//  ITBPostsDataSource.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//


#import "ITBPostsDataSource.h"

#import "ITBBaseEntity+Extension.h"
#import "ITBStorageManager.h"

#import "ITBMessage+Extension.h"

#import "AFHTTPSessionManager.h"
#import "AFHTTPRequestOperation.h"

static const NSUInteger ITBUndefinedId = NSUIntegerMax;

static const NSString * const ITBDataSourceMaxIdKey = @"max_id";
static const NSString * const ITBDataSourceMinIdKey = @"min_id";
static const NSString * const ITBDataSourceMoreKey = @"more";

NSString * const ITBUpdatingKeyPath = @"updating";
NSString * const ITBLoadingOneMoreKeyPath = @"loadingOneMorePage";

@interface ITBPostsDataSource (Additions)

+ (NSTimeInterval)updateTimeInterval;
+ (NSString *)entityName;
+ (void)clearLoadedEntities;

@end

@interface ITBPostsDataSource ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, assign, readwrite) BOOL updating;
@property (nonatomic, assign, readwrite) BOOL loadingOneMorePage;

@property (nonatomic, weak, readwrite) NSURLSessionDataTask *updateDataTask;
@property (nonatomic, weak, readwrite) NSURLSessionDataTask *loadOneMorePageDataTask;

@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSDate *backgroundEnteringDate;

@property (nonatomic, strong, readwrite) NSMutableArray *dataSourceArray;

@end

@implementation ITBPostsDataSource

+ (BOOL)automaticallyNotifiesObserversOfLoadingOneMorePage {
    return YES;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _loadingPageSize = 20;
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"identifier"];
        configuration.HTTPAdditionalHeaders = @{@"Authorization": @"Bearer AQAAAAAADGrdVFberCBgUAzuQt1brrJqk5-sH4uH7E8-kLlFAWDwTr6oSg6QipQ45BVBBcw0QdjM-no6mtllYup39NmUeO3wpg"};
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.app.net"]
                                                   sessionConfiguration:configuration];
        
        //TODO: more settings
    }
    
    return self;
}

- (void)prepareWork {
    self.canBeLoadMore = YES;
    
    [self _createFetchedResultsController];
}

- (void)reset {
    self.onDidEndPerformFetch = nil;
    [self.updateDataTask cancel];
    self.updateDataTask = nil;
    [self.loadOneMorePageDataTask cancel];
    self.loadOneMorePageDataTask = nil;
    
    _fetchedResultsController.delegate = nil;
}

- (void)dealloc
{
    [self reset];
    DBGLog(@"Dealloc %@", [self class]);
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

- (void)update
{
    if (_updating || _loadingOneMorePage) {
        // already updating
        return;
    }
    self.updating = YES;
    
    self.updateDataTask = [_sessionManager GET:@"posts/stream/global"
                                    parameters:@{@"count":@20}
                                       success:^(NSURLSessionDataTask *task, id responseObject) {
                                           [[self class] clearLoadedEntities];
                                           [self parseRequestResponse:responseObject[@"data"] meta:responseObject[@"meta"] completion:^(NSUInteger parsedCount) {
                                               
                                           }];
                                       }
                                       failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           if (error != nil) {
                                               ERROR_TO_LOG(@"error != nil, error = %@", error);
                                               self.updateDataTask = nil;
                                               self.updating = NO;
                                           }
                                       }];
}

- (void)loadOneMorePage
{
    if (_updating || _loadingOneMorePage || self.canBeLoadMore == NO) {
        return;
    }
    
    self.loadingOneMorePage = YES;
    
    ITBMessage *message = [ITBMessage findLastWithPredicate:nil inContext:[ITBStorageManager sharedInstance].mainThreadContext];
    self.updateDataTask = [_sessionManager GET:@"posts/stream/global"
                                    parameters:@{@"count":@20, @"before_id":message.identifier}
                                       success:^(NSURLSessionDataTask *task, id responseObject) {
                                           [self parseRequestResponse:responseObject[@"data"] meta:responseObject[@"meta"] completion:^(NSUInteger parsedCount) {

                                           }];
                                       }
                                       failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           if (error != nil) {
                                               ERROR_TO_LOG(@"error != nil, error = %@", error);
                                               self.updateDataTask = nil;
                                               self.loadingOneMorePage = NO;
                                           }
                                       }];
    
    //    JSONHTTPOperation *loadOneMorePageRequest = [self createLoadOneMorePageRequest];
    //    self.loadOneMorePageRequest = loadOneMorePageRequest;
    //    self.loadingOneMorePage = (_loadOneMorePageRequest != nil);
    //    weakify(self);
    //    [_loadOneMorePageRequest startOnDefaultQueueWithExecutionThreadCompletion:^(id result, NSError *error) {
    //        strongify(self);
    //        if (error != nil) {
    //            ERROR_TO_LOG(@"error != nil, error = %@", error);
    //            self.loadOneMorePageRequest = nil;
    //            self.loadingOneMorePage = NO;
    //        } else {
    //            // retain request to be available in block
    //            __block JSONHTTPOperation *request = self.updateRequest;
    //            [self parseRequestResponse:result completion:^(NSUInteger parsedCount) {
    //                if (parsedCount < [self loadingPageSize]) {
    //                    self.canBeLoadMore = NO;
    //                }
    //                if (parsedCount == 0) {
    //                    request = nil;
    //                    self.loadingOneMorePage = NO;
    //                }
    //            }];
    //        }
    //        self.updatedTriggeredAutomatically = NO;
    //    }];
}

- (void)parseRequestResponse:(NSArray *)dictionariesArray
                        meta:(NSDictionary *)meta
                  completion:(void (^)(NSUInteger parsedCount))completion {
    
    __block NSMutableArray *parsedObjects = [NSMutableArray array];
    //    __block NSDictionary *requestData = [self.updateRequest.dataDictionary copy];
    [self.storageManager saveDataSerialWithPrivateContextSupport:^(NSManagedObjectContext *privateContext) {
        if (self.loadOneMorePageDataTask) {
            //            requestData = self.loadOneMorePageDataTask.response.;
        }

        BOOL loadedPageIsLast = ![meta[ITBDataSourceMoreKey] boolValue];
        
        NSInteger firstID = [meta[ITBDataSourceMaxIdKey] integerValue];
        NSInteger lastID = [meta[ITBDataSourceMinIdKey] integerValue];

        
        NSString *entityName = [[self class] entityName];
        NSString *idKey = ITBIdentifierKey;
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
        // [id_last, id_first)
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier >= %@ && identifier < %@", [@(lastID) stringValue], [@(firstID) stringValue]];
        fetchRequest.includesPropertyValues = YES;
        NSError *executeError = nil;
        NSArray *existedObjects = [privateContext executeFetchRequest:fetchRequest error:&executeError];
        if (executeError) {
            DBGLog(@"%@", executeError);
        }
        
        // create id->task map for comfortable search for creation of newcomes
        NSMutableDictionary *idEntityDictionary = [NSMutableDictionary dictionary];
        
        for (ITBMessage *entity in existedObjects) {
            // In case of very bad SOMETHING happened(critical crash for example) - we need to force remove all possible duplicates.
            if (idEntityDictionary[entity.identifier]) {
                [privateContext deleteObject:entity];
            } else {
                [idEntityDictionary setObject:entity forKey:entity.identifier];
            }
        }
        
        // now parse response and create missed messages
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:privateContext];
        
        NSString *className = [NSString stringWithFormat:@"%@%@", PROJECT_PREFIX, entityName];
        Class class = NSClassFromString(className);
        
        /*
         3. Updating or creating messages with IDs
         */
        for (NSUInteger i = 0; i < dictionariesArray.count; i++) {
            NSMutableDictionary *dictionary = dictionariesArray[i];
            
            ITBMessage *message = idEntityDictionary[dictionary[idKey]];
            if (!message) {
                message = [[class alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:privateContext];
                
            } else {
                [idEntityDictionary removeObjectForKey:dictionary[idKey]];
            }
            [message updateWithDictionary:dictionary];
            [parsedObjects addObject:message];
        }
        
        /*
         4. Delete cached messages with id in the interval [id_last, id_first) (note, that id_first >= id_last).
         If id_first was not defined than we should remove all messages with id >= id_last (first page is loaded).
         If id_last was not defined - do nothing until step 6 (this will only happen if we loading first page and it is empty).
         */
        NSArray *oldObjects = [idEntityDictionary allValues];
        
        for (ITBMessage *entity in oldObjects) {
            [privateContext deleteObject:entity];
        }
        /*
         6. If loaded page is last (loaded messages count < requested count) than we should delete all messages with id < id_last.
         If id_last was not defined - remove all messages from cache (this will only happen if we loading first page and it is empty).
         Note: this step is necessary in case last message in the entire messages list was cached but than was removed from server.
         */
        if (loadedPageIsLast) {
            if (lastID == ITBUndefinedId) {
                fetchRequest.predicate = nil;
            } else {
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier < %@", [@(lastID) stringValue]];
            }
            NSError *executeError = nil;
            NSArray *objectsToDelete = [privateContext executeFetchRequest:fetchRequest error:&executeError];
            if (executeError) {
                ERROR_TO_LOG(@"%@", executeError);
            }
            for (ITBMessage *entity in objectsToDelete) {
                [privateContext deleteObject:entity];
            }
        }
    } completion:^(NSError *saveError){
        if (saveError != nil) {
            ERROR_TO_LOG(@"saveError = %@", saveError);
        } else {
            [self dataSourceSyncedAndShouldUpdateUI:(parsedObjects.count > 0)];
        }
        if (completion) {
            completion([parsedObjects count]);
        }
    }];
}

- (void)dataSourceSyncedAndShouldUpdateUI:(BOOL)shouldUpdateUI {
    if (shouldUpdateUI) {
//        [self performFetch];
    }
    self.updating = NO;
    self.loadingOneMorePage = NO;
    if (self.updateDataTask) {
        self.updateDataTask = nil;
    }
    if (self.loadOneMorePageDataTask) {
        self.loadOneMorePageDataTask = nil;
    }
}

#pragma mark - Accessors

- (NSArray *)dataSourceArray {
    return _fetchedResultsController.fetchedObjects;
}

- (ITBStorageManager *)storageManager {
    return [ITBStorageManager sharedInstance];
}

#pragma mark - private

- (void)didEndPerformFetch {
    if (self.onDidEndPerformFetch) {
        self.onDidEndPerformFetch();
    }
}

#pragma mark - Fetches from coreData

- (void)performFetch
{
    if (self.fetchedResultsController) {
        NSError *error;
        [self.fetchedResultsController performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        DBGLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [self didEndPerformFetch];
}

- (void)_createFetchedResultsController
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self class].entityName];
    fetchRequest.fetchBatchSize = 20;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.storageManager.mainThreadContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:@"ROOT"];
    [self performFetch];
}

@end

@implementation ITBPostsDataSource (SubclassOverride)

+ (void)clearLoadedEntities {
    [[ITBStorageManager sharedInstance] saveDataSerialWithPrivateContextSupport:^(NSManagedObjectContext *context) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
        NSError *executeError = nil;
        NSArray *existedObjects = [context executeFetchRequest:fetchRequest error:&executeError];
        for (NSManagedObject *object in existedObjects) {
            [object.managedObjectContext deleteObject:object];
        }
    } completion:^(NSError *error) {
        
    }];
}

+ (NSString *)entityName {
    return [ITBMessage entityName];
}

@end
