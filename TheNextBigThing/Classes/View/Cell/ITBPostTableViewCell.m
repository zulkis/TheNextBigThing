//
//  ITBPostTableViewCell.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBPostTableViewCell.h"
#import "ITBPost+Extension.h"
#import "ITBUser+Extension.h"

#import "ITBLinkLabel.h"
#import <UIImageView+WebCache.h>
#import "SORelativeDateTransformer.h"

static const CGFloat ITBDelimiterWidth = 8;

@interface ITBPostTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UILabel *fullnameLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;

@property (nonatomic, weak) IBOutlet ITBLinkLabel *postLabel;

@end

@implementation ITBPostTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)updateConstraintsWithTableViewWidth:(CGFloat)width {
    self.postLabel.preferredMaxLayoutWidth = width - (CGRectGetWidth(self.avatarImageView.frame) + ITBDelimiterWidth*3);
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
    
    self.postLabel.attributedText = post.attributedText;
    self.titleLabel.text = post.identifier;
    self.usernameLabel.text = [NSString stringWithFormat:@"@%@", post.user.username];
    self.fullnameLabel.text = post.user.fullname;
    
    self.timeLabel.text = [[SORelativeDateTransformer registeredTransformer] transformedValue:post.createdAt];
    
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:post.user.avatarImageUrl]
                            placeholderImage:[UIImage imageNamed:@"AvatarPlaceholdeIcon"]
                                     options:SDWebImageRetryFailed];
    
}

- (void)updateTimeLabel {
    self.timeLabel.text = [[SORelativeDateTransformer registeredTransformer] transformedValue:self.post.createdAt];
}

- (instancetype)init {
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] lastObject];
}

@end
