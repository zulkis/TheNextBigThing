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

#import "ITBPost+Extension.h"

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


@end

@implementation ITBPostsDataSource

+ (BOOL)automaticallyNotifiesObserversOfLoadingOneMorePage {
    return YES;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _loadingPageSize = 100;
        _cachedHeights = [NSMutableDictionary new];
        _horizontalCachedHeights = [NSMutableDictionary new];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
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
    
    ITBPost *message = [ITBPost findWithHighestIdentifierInContext:[ITBStorageManager sharedInstance].mainThreadContext];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"count":@(-self.loadingPageSize)}];
    if (message) {
        params[@"since_id"] = message.identifier;
    }
    
    self.updateDataTask = [_sessionManager GET:@"posts/stream/global"
                                    parameters:params
                                       success:^(NSURLSessionDataTask *task, id responseObject) {
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
    
    ITBPost *message = [ITBPost findWithLowestIdentifierInContext:[ITBStorageManager sharedInstance].mainThreadContext];
    self.updateDataTask = [_sessionManager GET:@"posts/stream/global"
                                    parameters:@{@"count":@(self.loadingPageSize), @"before_id":message.identifier}
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
}

- (void)parseRequestResponse:(NSArray *)dictionariesArray
                        meta:(NSDictionary *)meta
                  completion:(void (^)(NSUInteger parsedCount))completion {
    
    __block NSMutableArray *parsedObjects = [NSMutableArray array];
    [self.storageManager saveDataSerialWithPrivateContextSupport:^(NSManagedObjectContext *privateContext) {
        NSInteger firstID = [meta[ITBDataSourceMaxIdKey] integerValue];
        NSInteger lastID = [meta[ITBDataSourceMinIdKey] integerValue];

        NSString *entityName = [[self class] entityName];
        NSString *idKey = ITBIdentifierKey;
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
        
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier >= %@ && identifier < %@", [@(lastID) stringValue], [@(firstID) stringValue]];
        fetchRequest.includesPropertyValues = YES;
        NSError *executeError = nil;
        NSArray *existedObjects = [privateContext executeFetchRequest:fetchRequest error:&executeError];
        if (executeError) {
            DBGLog(@"%@", executeError);
        }
        
        // create id->task map for comfortable search for creation of newcomes
        NSMutableDictionary *idEntityDictionary = [NSMutableDictionary dictionary];
        
        for (ITBPost *entity in existedObjects) {
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
            Updating or creating messages with IDs
         */
        for (NSUInteger i = 0; i < dictionariesArray.count; i++) {
            NSMutableDictionary *dictionary = dictionariesArray[i];
            
            ITBPost *message = idEntityDictionary[dictionary[idKey]];
            if (!message) {
                message = [[class alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:privateContext];
                
            } else {
                [idEntityDictionary removeObjectForKey:dictionary[idKey]];
            }
            [message updateWithDictionary:dictionary];
            [parsedObjects addObject:message];
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
    fetchRequest.fetchBatchSize = 10;
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
    return [ITBPost entityName];
}

@end
