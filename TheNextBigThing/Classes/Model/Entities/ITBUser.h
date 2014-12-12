//
//  ITBUser.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBBaseEntity+Extension.h"

@class ITBMessage;

@interface ITBUser : ITBBaseEntity

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSString * avatarImageUrl;
@property (nonatomic, retain) NSSet *messages;
@end

@interface ITBUser (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(ITBMessage *)value;
- (void)removeMessagesObject:(ITBMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
