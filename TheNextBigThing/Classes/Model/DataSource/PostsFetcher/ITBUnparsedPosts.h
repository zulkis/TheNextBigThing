//
//  ITBUnparsedPosts.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 15/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITBUnparsedPosts : NSObject

@property (nonatomic, copy, readonly) NSString *firstId;
@property (nonatomic, copy, readonly) NSString *lastId;

@property (nonatomic, readonly) BOOL couldLoadMore;

@property (nonatomic, strong, readonly) NSArray *posts;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
