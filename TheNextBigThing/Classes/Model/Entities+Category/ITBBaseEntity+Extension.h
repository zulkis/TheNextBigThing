//
//  ITBBaseEntity+Extension.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBBaseEntity.h"
#import "NSManagedObject+Extension.h"

extern NSString *const ITBIdentifierKey;

@interface ITBBaseEntity (Extension)

+ (NSUInteger)countWithPredicate:(NSPredicate *)predicate fetchLimit:(NSInteger)fetchLimit inContext:(NSManagedObjectContext *)context;

+ (instancetype)findLastWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (instancetype)findFirstWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (instancetype)findOrCreateWithIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context;

@end
