//
//  ITBPostsBuilder.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 15/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITBStream, ITBUnparsedPosts;

@interface ITBPostsBuilder : NSObject

- (instancetype)initWithStream:(ITBStream *)stream;

- (void)makePostsFromUnparsedPostsData:(ITBUnparsedPosts *)unparsedPostsData completion:(void(^)(NSError *error))completion;

@end
