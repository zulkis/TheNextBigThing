//
//  ITBTableView.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/13/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ITBTableView : UITableView

@property (nonatomic, strong, readonly) UIRefreshControl *refreshControl;

@property (nonatomic, weak, readonly) UIView *scrollIndicatorView;

- (void)setShouldShowRefreshControl:(BOOL)value;

@end
