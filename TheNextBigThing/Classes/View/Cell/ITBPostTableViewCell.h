//
//  ITBPostTableViewCell.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ITBPost;

@interface ITBPostTableViewCell : UITableViewCell

@property (nonatomic, weak) ITBPost *post;

- (void)updateConstraintsWithTableViewWidth:(CGFloat)width;

@end
