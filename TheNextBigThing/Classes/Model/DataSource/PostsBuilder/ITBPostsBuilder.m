//
//  ITBPostsBuilder.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 15/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBPostsBuilder.h"
#import "ITBStream.h"
#import "ITBStorageManager.h"
#import "ITBUnparsedPosts.h"

#import "ITBPost+Extension.h"

@interface ITBPostsBuilder ()

@property (nonatomic, weak) ITBStream *stream;

@end

@implementation ITBPostsBuilder

- (instancetype)initWithStream:(ITBStream *)stream {
    self = [super init];
    if (self) {
        _stream = stream;
    }
    return self;
}

- (void)makePostsFromUnparsedPostsData:(ITBUnparsedPosts *)unparsedPostsData completion:(void(^)(NSError *error))completion {
    if (!self.stream) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Stream must not be nil" userInfo:nil];
    }
    
    __block NSMutableArray *parsedObjects = [NSMutableArray array];
    [self.stream.storageManager saveDataSerialWithPrivateContextSupport:^(NSManagedObjectContext *privateContext) {
        NSString *firstID = unparsedPostsData.firstId;
        NSString *lastID = unparsedPostsData.lastId;
        NSArray *dictionariesArray = unparsedPostsData.posts;
        if (dictionariesArray.count == 0) {
            return;
        }
        
        NSString *entityName = [ITBPost entityName];
        NSString *idKey = ITBIdentifierKey;
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
        
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier >= %@ && identifier < %@", lastID, firstID];
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
        if (completion) {
            completion(saveError);
        }
    }];
}

@end
