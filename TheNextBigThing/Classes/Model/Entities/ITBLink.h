//
//  ITBLink.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 14/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "NSManagedObject+Extension.h"

@class ITBPost;

@interface ITBLink : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSNumber * location;
@property (nonatomic, retain) ITBPost *post;

@end
