//
//  ITBMessage.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttiBitty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface ITBMessage : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) User *user;

@end
