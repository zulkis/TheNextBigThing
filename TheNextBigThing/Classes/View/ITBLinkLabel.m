//
//  ITBLinkLabel.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 14/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBLinkLabel.h"
#import "CoreTextUtils.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

#import <UIAlertView+BlocksKit.h>
#import <OHAttributedStringAdditions.h>

@interface ITBLinkLabel () <UIGestureRecognizerDelegate> {
    CTFrameRef textFrame;
    CGRect drawingRect;
    NSURL *_urlToOpen;
    
    NSAttributedString *_initialAttributedString;
}

@property (nonatomic, strong) UILongPressGestureRecognizer *linksTapGestureRecognizer;

@end

@implementation ITBLinkLabel

- (void)awakeFromNib {
    [super awakeFromNib];
    self.highlightedLinkColor = [UIColor colorWithWhite:0.4f alpha:0.3f];
    
    self.linksTapGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_gestureRecognised:)];
    self.linksTapGestureRecognizer.minimumPressDuration = 0.2;
    self.linksTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.linksTapGestureRecognizer];
}



-(void)_gestureRecognised:(UIGestureRecognizer*)sender
{
    CGPoint location = [sender locationInView:self];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
            [string addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, self.attributedText.length)];
            
            NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:string];
            NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
            [textStorage addLayoutManager:layoutManager];
            
            // init text container
            CGSize size = CGSizeMake(ceilf(sender.view.bounds.size.width), CGFLOAT_MAX);
            
            NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:size];
            textContainer.lineFragmentPadding  = 0;
            textContainer.maximumNumberOfLines = self.numberOfLines;
            textContainer.lineBreakMode        = self.lineBreakMode;
            textContainer.layoutManager        = layoutManager;
            
            [layoutManager addTextContainer:textContainer];
            [layoutManager setTextStorage:textStorage];
            
            NSUInteger characterIndex = [layoutManager characterIndexForPoint:location
                                                              inTextContainer:textContainer
                                     fractionOfDistanceBetweenInsertionPoints:NULL];
            
            NSRange range = NSMakeRange(0, 0);
            
            _urlToOpen = [self.attributedText URLAtIndex:characterIndex effectiveRange:&range];
            
            if (_urlToOpen)
            {
                _initialAttributedString = self.attributedText;
                
                UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@""
                                                                    message:[NSString stringWithFormat:LOC(@"common.openUrlFormat"), [_urlToOpen absoluteString]]];
                
                [alertView bk_setCancelButtonWithTitle:LOC(@"common.no") handler:nil];
                [alertView bk_addButtonWithTitle:LOC(@"common.yes") handler:^{
                    if (_urlToOpen) {
                        [[UIApplication sharedApplication] openURL:_urlToOpen];
                    }
                    _urlToOpen = nil;
                    
                }];
                [alertView bk_setWillDismissBlock:^(UIAlertView *alertView, NSInteger index) {
                    self.attributedText = _initialAttributedString;
                    _initialAttributedString = nil;
                    [self setNeedsDisplay];
                }];
                [alertView show];
                
                NSMutableAttributedString *str = [NSMutableAttributedString attributedStringWithAttributedString:self.attributedText];
                [str setTextColor:self.highlightedLinkColor range:range];
                [str setURL:nil range:range];
                
                self.attributedText = str;
                [self setNeedsDisplay];
            }
            
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStatePossible:
            break;
    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return NO;
}

@end
