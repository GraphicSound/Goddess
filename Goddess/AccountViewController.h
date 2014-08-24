//
//  AccountViewController.h
//  Goddess
//
//  Created by yu_hao on 3/31/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignUpViewController.h"
#import "EditAccountViewController.h"

@interface AccountViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

+ (AccountViewController *)sharedManager;

@property (weak, nonatomic) IBOutlet UITableView *accountTableView;

@property bool login;
@property NSString *userIDString;
@property NSString *email;
@property NSString *md5;
@property UIImage *portraitImage;
@property NSString *name;
@property int gender;
@property NSString *contact;
@property NSString *signature;

- (void)readAccountDataFromFile;

- (IBAction)test:(id)sender;

@end
