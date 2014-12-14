//
//  ITBPost.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBPost.h"
#import "ITBUser.h"
#import "ITBLink.h"

#import <NSAttributedString+OHAdditions.h>
#import <NSMutableAttributedString+OHAdditions.h>

@implementation ITBPost

@synthesize attributedText = _attributedText;

@dynamic html;
@dynamic text;
@dynamic identifier;
@dynamic createdAt;
@dynamic user;
@dynamic links;

- (NSAttributedString *)attributedText {
    if (!self.text) {
        return [NSAttributedString attributedStringWithString:@""];
    }
    if (!_attributedText) {
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.text];
        for (ITBLink *link in self.links) {
            [string setURL:[NSURL URLWithString:link.url] range:NSMakeRange(link.location.integerValue, link.length.integerValue)];
        }
        _attributedText = [string copy];
    }
    return _attributedText;
}

@end
