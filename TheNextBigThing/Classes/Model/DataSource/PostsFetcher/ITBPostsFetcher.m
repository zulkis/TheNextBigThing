//
//  ITBPostsFetcher.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 15/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBPostsFetcher.h"
#import "ITBUnparsedPosts.h"

#import <AFHTTPSessionManager.h>

@interface ITBPostsFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, weak) NSURLSessionDataTask *getDataTask;

@end

@implementation ITBPostsFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.HTTPAdditionalHeaders = @{@"Authorization": @"Bearer AQAAAAAADGrdVFberCBgUAzuQt1brrJqk5-sH4uH7E8-kLlFAWDwTr6oSg6QipQ45BVBBcw0QdjM-no6mtllYup39NmUeO3wpg"};
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.app.net"]
                                                   sessionConfiguration:configuration];
    }
    return self;
}

- (void)getPostsWithParams:(NSDictionary *)params completion:(void (^)(ITBUnparsedPosts *, NSError *))completion {
    self.getDataTask = [_sessionManager GET:@"posts/stream/global"
                                    parameters:params
                                       success:^(NSURLSessionDataTask *task, id responseObject) {
                                           ITBUnparsedPosts *unparsedPosts = [[ITBUnparsedPosts alloc] initWithDictionary:responseObject];
                                           completion (unparsedPosts, nil);
                                       }
                                       failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           completion (nil, error);
                                       }];
}

- (void)dealloc {
    [self.getDataTask cancel];
}

@end
