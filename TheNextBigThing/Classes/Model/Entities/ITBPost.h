//
//  ITBPost.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttyBitty. All rights reserved.
//

#import "ITBBaseEntity+Extension.h"

@class ITBUser, ITBLink;

@interface ITBPost : ITBBaseEntity

@property (nonatomic, retain, readonly) NSAttributedString *attributedText;

@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) ITBUser *user;
@property (nonatomic, retain) NSSet *links;

@end

@interface ITBPost (CoreDataGeneratedAccessors)

- (void)addLinksObject:(ITBLink *)value;
- (void)removeLinksObject:(ITBLink *)value;
- (void)addLinks:(NSSet *)values;
- (void)removeLinks:(NSSet *)values;

@end
