//
//  UserInfoViewController.h
//  Goddess
//
//  Created by yu_hao on 4/3/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserInfoCell.h"
#import "SeparateCell.h"
#import "PostHistoryCell.h"

@interface UserInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property int userID;
@property bool retrieved;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property UIImage *portraitImage;
@property NSString *name;
@property int gender;
@property NSString *contact;
@property NSString *signature;

@end
