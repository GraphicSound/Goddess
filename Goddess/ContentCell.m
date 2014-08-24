//
//  ContentCell.m
//  Godess
//
//  Created by yu_hao on 3/29/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "ContentCell.h"

@implementation ContentCell

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
        NSLog(@"contentcell initWithCoder...");
    }
    return self;
}

- (IBAction)lightUp:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"警告" message:@"你每天只有一次机会为别人爆灯，请慎重考虑! (爆灯表示你对其相当有感觉)"
                          
                                                   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"爆灯！", nil];
    [alert show];
}

- (IBAction)thumbUp:(id)sender {
}

//因为cell里不能使用performSegueWithIdentifier，导致传参数很麻烦；而使用presentViewController，又不好找navi
- (IBAction)portraitImageTouched:(id)sender {
    NSLog(@"contentcell portraitImageView %d", self.portraitImageView.tag);
    [self.delegate showUserInfoViewControllerByUserID:self.portraitImageView.tag];
}

@end
