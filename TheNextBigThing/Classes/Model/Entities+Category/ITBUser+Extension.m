//
//  ITBUser+Extension.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBUser+Extension.h"

static NSString * const ITBUsernameKey = @"username";
static NSString * const ITBFullnameKey = @"fullname";
static NSString * const ITBAvatarUrlKeyPath = @"avatar_image.url";

@implementation ITBUser (Extension)

- (void)updateWithDictionary:(NSDictionary *)dictionary {
    [super updateWithDictionary:dictionary];
    
    self.username = dictionary[ITBUsernameKey];
    self.fullname = dictionary[ITBFullnameKey];
    self.avatarImageUrl = [dictionary valueForKeyPath:ITBAvatarUrlKeyPath];
}

@end
