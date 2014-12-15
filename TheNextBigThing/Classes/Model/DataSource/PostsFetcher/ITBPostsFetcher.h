//
//  ITBPostsFetcher.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 15/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITBUnparsedPosts;

@interface ITBPostsFetcher : NSObject

- (void)getPostsWithParams:(NSDictionary *)params completion:(void(^)(ITBUnparsedPosts *unparsedPosts, NSError *error))completion;

@end
