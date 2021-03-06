//
//  ITBStorageManager.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "NSManagedObjectContext+Saving.h"

@interface ITBStorageManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) NSManagedObjectContext *mainThreadContext;

- (NSManagedObjectContext *)privateContext;

- (void)saveDataSerialWithPrivateContextSupport:(void(^)(NSManagedObjectContext *context))saveBlock
                                     completion:(void(^)(NSError *error))completion;

@end
