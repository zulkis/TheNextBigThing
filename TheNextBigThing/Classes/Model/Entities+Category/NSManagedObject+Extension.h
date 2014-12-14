//
//  NSManagedObject+Extension.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 14/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Extension)

- (void)updateWithDictionary:(NSDictionary *)dictionary;

+ (NSString *)entityName;
+ (instancetype)createInContext:(NSManagedObjectContext *)context;

- (void)deleteEntity;

- (instancetype)inContext:(NSManagedObjectContext *)otherContext;

+ (NSArray *)findAllWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

@end
