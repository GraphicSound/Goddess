//
//  CommentCell.m
//  Goddess
//
//  Created by yu_hao on 4/4/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "CommentCell.h"

@implementation CommentCell

@synthesize commentUserNameLabel = _commentUserNameLabel;
@synthesize commentLabel = _commentLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//storyboard里面的上面不会被调用
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Do your custom initialization here
        NSLog(@"contentcell initWithCoder...");
        if (self.commentUserNameLabel == nil) {
            self.commentUserNameLabel = [UILabel new];
        }
        if (self.commentLabel == nil) {
            self.commentLabel = [UILabel new];
        }
    }
    return self;
}

@end
