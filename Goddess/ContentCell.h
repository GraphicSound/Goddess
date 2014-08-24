//
//  ContentCell.h
//  Godess
//
//  Created by yu_hao on 3/29/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ContentCellDelegate <NSObject>
@required
- (void)showUserInfoViewControllerByUserID:(int)userID;
@end

@interface ContentCell : UITableViewCell

@property id <ContentCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *systemNameAndVersionLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;
@property NSArray *imageLinksArray;

@property (weak, nonatomic) IBOutlet UIButton *lightbulbButton;
@property (weak, nonatomic) IBOutlet UIButton *thumbUpButton;
@property (weak, nonatomic) IBOutlet UIView *commentView;
@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
- (IBAction)lightUp:(id)sender;
- (IBAction)thumbUp:(id)sender;
- (IBAction)portraitImageTouched:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentViewHeightConstraint;

@end
