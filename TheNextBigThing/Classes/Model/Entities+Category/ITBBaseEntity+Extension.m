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

+ (NSString *)entityName {
    NSString *className = NSStringFromClass([self class]);
    if ([className hasPrefix:PROJECT_PREFIX]) {
        return [className substringFromIndex:PROJECT_PREFIX.length];
    } else if ([className hasPrefix:@"Core"]) {
        return [className substringFromIndex:4];
    }
    return className;
}

+ (instancetype)createInContext:(NSManagedObjectContext *)context {
    ITBBaseEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
    return entity;
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

+ (NSArray *)findAllWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = predicate;
    NSError *error;
    return [context executeFetchRequest:fetchRequest error:&error];
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

+ (instancetype)findOrCreateWithIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context {
    ITBBaseEntity *entity = [self findFirstWithPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier] inContext:context];
    if (!entity) {
        entity = [self createInContext:context];
        entity.identifier = identifier;
    }
    return entity;
}

- (void)deleteEntity
{
    [[self managedObjectContext] deleteObject:self];
}

- (id)inContext:(NSManagedObjectContext *)otherContext
{
    NSError *error;
    NSManagedObject *inContext = [otherContext existingObjectWithID:self.objectID error:&error];
    if (error) {
        inContext = [otherContext objectWithID:self.objectID];
    }
    
    return inContext;
}

@end
