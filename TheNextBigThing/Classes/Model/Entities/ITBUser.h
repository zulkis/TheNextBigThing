//
//  ITBUser.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBBaseEntity+Extension.h"

@class ITBPost;

@interface ITBUser : ITBBaseEntity

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * fullname;
@property (nonatomic, retain) NSString * avatarImageUrl;
@property (nonatomic, retain) NSSet *posts;
@end

@interface ITBUser (CoreDataGeneratedAccessors)

- (void)addPostsObject:(ITBPost *)value;
- (void)removePostsObject:(ITBPost *)value;
- (void)addPosts:(NSSet *)values;
- (void)removePosts:(NSSet *)values;

@end
