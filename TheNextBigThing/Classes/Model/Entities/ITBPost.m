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

- (NSWritingDirection)textDirection {
    NSString *isoLangCode = (__bridge_transfer NSString*)CFStringTokenizerCopyBestStringLanguage((__bridge CFStringRef)self.text, CFRangeMake(0, self.text.length));
    NSLocaleLanguageDirection direction = [NSLocale characterDirectionForLanguage:isoLangCode];
    switch (direction) {
        case NSLocaleLanguageDirectionUnknown:
        case NSLocaleLanguageDirectionBottomToTop:
        case NSLocaleLanguageDirectionTopToBottom:
            return NSWritingDirectionNatural;
            break;
            
        case NSLocaleLanguageDirectionLeftToRight:
            return NSWritingDirectionLeftToRight;
            break;
        case NSLocaleLanguageDirectionRightToLeft:
            return NSWritingDirectionRightToLeft;
            break;
        default:
            break;
    }
}

- (NSAttributedString *)attributedText {
    if (!self.text) {
        return [NSAttributedString attributedStringWithString:@""];
    }
    if (!_attributedText) {
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.baseWritingDirection = [self textDirection];
        
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
        attributes[NSParagraphStyleAttributeName] = paragraph;
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributes];
        
        for (ITBLink *link in self.links) {
            [string setURL:[NSURL URLWithString:link.url] range:NSMakeRange(link.location.integerValue, link.length.integerValue)];
        }
        _attributedText = [string copy];
    }
    return _attributedText;
}

@end
