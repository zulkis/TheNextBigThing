//
//  ITBUnparsedPosts.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 15/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBUnparsedPosts.h"

static const NSString * const ITBMetaKey = @"meta";
static const NSString * const ITBDataKey = @"data";

static const NSString * const ITBMetaMaxIdKey = @"max_id";
static const NSString * const ITBMetaMinIdKey = @"min_id";
static const NSString * const ITBMetaMoreKey = @"more";

@implementation ITBUnparsedPosts

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        NSDictionary *meta = dict[ITBMetaKey];
        _firstId =  meta[ITBMetaMaxIdKey];
        _lastId = meta[ITBMetaMinIdKey];
        _couldLoadMore = [meta[ITBMetaMoreKey] boolValue];
        
        _posts = dict[ITBDataKey];
    }
    return self;
}

@end
