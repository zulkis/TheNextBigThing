//
//  ITBPostTableViewCell.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBPostTableViewCell.h"
#import "ITBPost+Extension.h"

#import <NSAttributedString+OHAdditions.h>

@interface ITBPostTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *postLabel;

@property (nonatomic, strong) UITapGestureRecognizer *linksTapGestureRecognizer;

@end

@implementation ITBPostTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.linksTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_onGestureRecognizerTap:)];
    [self.postLabel addGestureRecognizer:self.linksTapGestureRecognizer];
}

+ (instancetype)dummyCell {
    static dispatch_once_t onceToken;
    static ITBPostTableViewCell *cell;
    dispatch_once(&onceToken, ^{
        cell = [ITBPostTableViewCell new];
    });
    return cell;
}

- (void)setPost:(ITBPost *)post {
    _post = post;
    
    self.postLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.postLabel.frame);
    
    self.postLabel.attributedText = post.attributedText;
    self.titleLabel.text = post.identifier;
}

- (instancetype)init {
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] lastObject];
}

#pragma mark - GestureRecognizer

- (void)_onGestureRecognizerTap:(UITapGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:sender.view];
    
    // init text storage
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:self.postLabel.attributedText];
    [string addAttribute:NSFontAttributeName value:self.postLabel.font range:NSMakeRange(0, self.postLabel.attributedText.length)];
    
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:string];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    
    // init text container
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:sender.view.bounds.size];
    textContainer.lineFragmentPadding  = 0;
    textContainer.maximumNumberOfLines = self.postLabel.numberOfLines;
    textContainer.lineBreakMode        = self.postLabel.lineBreakMode;
    textContainer.layoutManager        = layoutManager;
    
    [layoutManager addTextContainer:textContainer];
    [layoutManager setTextStorage:textStorage];
    
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:location
                                                      inTextContainer:textContainer
                             fractionOfDistanceBetweenInsertionPoints:NULL];
    
    NSRangePointer rangePtr = nil;
    NSURL *url = [self.postLabel.attributedText URLAtIndex:characterIndex effectiveRange:rangePtr];
    NSLog(@"URL: %@", url);
}

@end
