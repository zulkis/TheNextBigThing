//
//  ITBMessage+Extension.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBMessage+Extension.h"
#import "ITBUser+Extension.h"

static NSString * const ITBTextKey = @"text";
static NSString * const ITBCreatedAtKey = @"created_at";
static NSString * const ITBUserKey = @"user";

@implementation ITBMessage (Extension)

+ (NSDateFormatter *)createdAtDateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";
    });
    
    return dateFormatter;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary {
    [super updateWithDictionary:dictionary];
    
    self.text = dictionary[ITBTextKey];
    self.createdAt = [[[self class] createdAtDateFormatter] dateFromString:dictionary[ITBCreatedAtKey]];
    
    NSDictionary *userDict = dictionary[ITBUserKey];
    NSString *userId = userDict[ITBIdentifierKey];
    if (userId != nil) {
        ITBUser *user = [ITBUser findOrCreateWithIdentifier:userId inContext:self.managedObjectContext];
        [user updateWithDictionary:userDict];
        self.user = user;
    }
}

@end
