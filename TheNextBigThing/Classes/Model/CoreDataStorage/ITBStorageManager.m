//
//  ITBStorageManager.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//


#import "ITBStorageManager.h"

#import <CoreData/CoreData.h>

static NSString *const DBFileName = @"storage.sqlite";

@interface ITBStorageManager ()

@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSManagedObjectContext *privateWriterContext;

@property (nonatomic, strong) dispatch_queue_t saveQueue;

- (NSURL *)_storeUrl;

- (NSURL *)_storeFolderUrl;

@end


@implementation ITBStorageManager

@synthesize mainThreadContext = _lazyLoadMainThreadContext;
@synthesize persistentStoreCoordinator = _lazyLoadPersistentStoreCoordinator;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static ITBStorageManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (NSPersistentStore *)persistentStore {
    return [_lazyLoadPersistentStoreCoordinator.persistentStores firstObject];
}

- (NSManagedObjectContext *)mainThreadContext
{
    if ([NSThread isMainThread] == NO) {
        ERROR_TO_LOG(@"[NSThread isMainThread] == NO");
        return nil;
    }
    
    if (_lazyLoadMainThreadContext != nil) {
        return _lazyLoadMainThreadContext;
    }
    
    [self _prepareMainContexts];
    
    return _lazyLoadMainThreadContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_lazyLoadPersistentStoreCoordinator != nil) {
        return _lazyLoadPersistentStoreCoordinator;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"storage" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSURL *storeURL = [self _storeUrl];
    
    NSError *error = nil;
    _lazyLoadPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    
    NSMutableDictionary *sqliteOptions = [NSMutableDictionary dictionary];
    [sqliteOptions setObject:@"WAL" forKey:@"journal_mode"];
    
    NSDictionary *storeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                             @YES, NSMigratePersistentStoresAutomaticallyOption,
                             @YES, NSInferMappingModelAutomaticallyOption,
                             sqliteOptions, NSSQLitePragmasOption,
                             nil];
    NSPersistentStore *store = [_lazyLoadPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:storeOptions error:&error];
    if (store == nil) {
        ERROR_TO_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
        // remove it and create new one
        NSError *removeError = nil;
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&removeError];
        if (removeError != nil) {
            ERROR_TO_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
        }
        store = [_lazyLoadPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
        if (store == nil) {
            ERROR_TO_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
    
    return _lazyLoadPersistentStoreCoordinator;
}

- (NSManagedObjectContext *)privateContext
{
    [self _prepareMainContexts];
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = _lazyLoadMainThreadContext;
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    return context;
}

- (dispatch_queue_t)saveQueue {
    if (!_saveQueue) {
        _saveQueue = dispatch_queue_create([NSStringFromClass([ITBStorageManager class]) UTF8String], 0);
    }
    return _saveQueue;
}

- (NSManagedObjectContext *)_saveDataInPrivateContext:(void(^)(NSManagedObjectContext *context))saveBlock error:(NSError **)error;
{
    NSManagedObjectContext *context = self.privateContext;
    saveBlock(context);
    if ([context hasChanges])
    {
        [context saveSynchronously:YES completion:^(BOOL success, NSError *err) {
            if (err) {
                DBGLog(@"%@", err);
                *error = [NSError errorWithDomain:err.domain code:err.code userInfo:err.userInfo];
            }
        }];
    }
    return context;
}

- (void)saveDataSerialWithPrivateContextSupport:(void(^)(NSManagedObjectContext *context))saveBlock
                                     completion:(void(^)(NSError *error))completion {

    dispatch_async([self saveQueue], ^{
        NSError *error = nil;
        [self _saveDataInPrivateContext:saveBlock error:&error];
        dispatch_sync(dispatch_get_main_queue(), ^{
            completion(error);
        });
    });
}

- (void)dealloc {
    DBGLog(@"deallocated: %@", self);
}

#pragma mark Private

- (void)_prepareMainContexts {
    if (_lazyLoadMainThreadContext) {
        return;
    }
    _privateWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_privateWriterContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    
    _lazyLoadMainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _lazyLoadMainThreadContext.parentContext = _privateWriterContext;
    _lazyLoadMainThreadContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
}

- (NSURL *)_storeUrl
{
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *sqlFilePath = [libraryPath stringByAppendingFormat:@"/%@", DBFileName];
    NSURL *storeURL = [NSURL fileURLWithPath:sqlFilePath];
    return storeURL;
}

- (NSURL *)_storeFolderUrl
{
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSURL *storeURL = [NSURL fileURLWithPath:libraryPath];
    return storeURL;
}

@end
