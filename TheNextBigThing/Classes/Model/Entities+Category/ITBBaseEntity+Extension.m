//
//  ITBBaseEntity+Extension.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBBaseEntity+Extension.h"

NSString *const ITBIdentifierKey = @"id";

@implementation ITBBaseEntity (Extension)

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    self.identifier = dictionary[ITBIdentifierKey];
}

+ (instancetype)findOrCreateWithIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context {
    ITBBaseEntity *entity = [self findFirstWithPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier] inContext:context];
    if (!entity) {
        entity = [self createInContext:context];
        entity.identifier = identifier;
    }
    return entity;
}

+ (instancetype)findLastWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    
    NSError *error = nil;
    
    return [context executeFetchRequest:fetchRequest error:&error].lastObject;
}

+ (instancetype)findFirstWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    NSError *error;
    return [[context executeFetchRequest:fetchRequest error:&error] lastObject];
}


+ (NSUInteger)countWithPredicate:(NSPredicate *)predicate fetchLimit:(NSInteger)fetchLimit inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.fetchLimit = fetchLimit;
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    fetchRequest.returnsObjectsAsFaults = NO;
    
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    
    if (error != nil) {
        ERROR_TO_LOG(@"error = %@", error);
    }
    
    return count;
}

@end
