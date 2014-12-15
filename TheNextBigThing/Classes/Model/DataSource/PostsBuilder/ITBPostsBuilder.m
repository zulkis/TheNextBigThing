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
    
    [self.stream.storageManager saveDataSerialWithPrivateContextSupport:^(NSManagedObjectContext *privateContext) {
        NSArray *dictionariesArray = unparsedPostsData.posts;
        if (dictionariesArray.count == 0) {
            return;
        }
        
        NSString *entityName = [ITBPost entityName];
        
        // now parse response and create missed messages
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:privateContext];
        NSString *className = [NSString stringWithFormat:@"%@%@", PROJECT_PREFIX, entityName];
        Class class = NSClassFromString(className);
        
        /*
         Updating or creating messages with IDs
         */
        for (NSUInteger i = 0; i < dictionariesArray.count; i++) {
            NSMutableDictionary *dictionary = dictionariesArray[i];
            ITBPost *post = [[class alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:privateContext];
            [post updateWithDictionary:dictionary];
        }
    } completion:^(NSError *saveError){
        if (completion) {
            completion(saveError);
        }
    }];
}

@end
