//
//  ITBBaseEntity.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface ITBBaseEntity : NSManagedObject

@property (nonatomic, retain) NSString * identifier;

@end
