//
//  NSManagedObject+Extension.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 14/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "NSManagedObject+Extension.h"

@implementation NSManagedObject (Extension)

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    
}

+ (NSString *)entityName {
    NSString *className = NSStringFromClass([self class]);
    if ([className hasPrefix:PROJECT_PREFIX]) {
        return [className substringFromIndex:PROJECT_PREFIX.length];
    }
    return className;
}

+ (instancetype)createInContext:(NSManagedObjectContext *)context {
    NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
    return entity;
}

+ (NSArray *)findAllWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = predicate;
    NSError *error;
    return [context executeFetchRequest:fetchRequest error:&error];
}

- (void)deleteEntity
{
    [[self managedObjectContext] deleteObject:self];
}

- (instancetype)inContext:(NSManagedObjectContext *)otherContext
{
    NSError *error;
    NSManagedObject *inContext = [otherContext existingObjectWithID:self.objectID error:&error];
    if (error) {
        inContext = [otherContext objectWithID:self.objectID];
    }
    
    return inContext;
}

@end
