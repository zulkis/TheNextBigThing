//
//  ITBTableView.m
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/13/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBTableView.h"

@interface ITBTableView ()
{
    UIView * __weak _lazyLoadScrollIndicatorView;
}

@property (nonatomic, strong) UITableViewController *tableViewController;

@end

@implementation ITBTableView

@dynamic scrollIndicatorView;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _tableViewController = [UITableViewController new];
        _refreshControl = [UIRefreshControl new];
        
        _tableViewController.tableView = self;
        _tableViewController.refreshControl = _refreshControl;
    }
    return self;
}

- (void)setShouldShowRefreshControl:(BOOL)value {
    self.tableViewController.refreshControl = value ? _refreshControl : nil;
}


- (UIView *)scrollIndicatorView
{
    if (_lazyLoadScrollIndicatorView == nil) {
        for (UIView *subView in self.subviews) {
            if (subView.frame.origin.x > (self.frame.size.width - 10.0f)) {
                _lazyLoadScrollIndicatorView = subView;
                break;
            } 
        }
    }
    
    return _lazyLoadScrollIndicatorView;
}


@end
