//
//  ITBPost+Extension.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBPost+Extension.h"
#import "ITBUser+Extension.h"
#import "ITBLink.h"

static NSString * const ITBTextKey = @"text";
static NSString * const ITBCreatedAtKey = @"created_at";
static NSString * const ITBUserKey = @"user";

static NSString * const ITBLinksKeyPath = @"entities.links";
static NSString * const ITBLinkLocationKey = @"pos";
static NSString * const ITBLinkLengthKey = @"len";
static NSString * const ITBLinkUrlKey = @"url";

@implementation ITBPost (Extension)

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
    
    if (![self.links count]) {
        NSArray *links = [dictionary valueForKeyPath:ITBLinksKeyPath];
        [links enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            ITBLink *link = [ITBLink createInContext:self.managedObjectContext];
            link.location = obj[ITBLinkLocationKey];
            link.length = obj[ITBLinkLengthKey];
            link.url = obj[ITBLinkUrlKey];
            
            [self addLinksObject:link];
        }];
    }
    
    NSDictionary *userDict = dictionary[ITBUserKey];
    NSString *userId = userDict[ITBIdentifierKey];
    if (userId != nil) {
        ITBUser *user = [ITBUser findOrCreateWithIdentifier:userId inContext:self.managedObjectContext];
        [user updateWithDictionary:userDict];
        self.user = user;
    } else {
        NSLog(@"");
    }
}



@end
