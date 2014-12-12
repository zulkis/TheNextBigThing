//
//  User.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttiBitty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ITBMessage;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) id avatarImage;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSSet *messages;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(ITBMessage *)value;
- (void)removeMessagesObject:(ITBMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
