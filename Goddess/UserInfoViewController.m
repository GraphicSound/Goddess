//
//  UserInfoViewController.m
//  Goddess
//
//  Created by yu_hao on 4/3/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "UserInfoViewController.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
#define serverUrl @"http://223.26.60.51/goddess"//2

@interface UserInfoViewController ()

@end

@implementation UserInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //获取用户信息
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"%d", self.userID);
    NSString *registerString = [NSString stringWithFormat:@"%@/api.php?api=9&userID=%d", serverUrl, self.userID];
    NSURL *registerUrl = [NSURL URLWithString:[registerString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSError* error = nil;
    NSData* _responseData = [NSData dataWithContentsOfURL:registerUrl
                                                  options:NSDataReadingUncached
                                                    error:&error];//居然能如此简单！！！
    NSString *respondString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];  //现在是md5值
    NSLog(@"%@", respondString);
    
    NSArray *userInfoArrayFromRemoteJson = [NSJSONSerialization
                                            JSONObjectWithData:_responseData //1
                                            options:kNilOptions
                                            error:&error];
    if (error) {
        NSLog(@"数据有错");
        return;
    }
    NSDictionary *userInfoDic = [userInfoArrayFromRemoteJson objectAtIndex:0];
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@/usr_portraitImages/%@", serverUrl, [userInfoDic objectForKey:@"portraitImageLink"]]);
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/usr_portraitImages/%@", serverUrl, [userInfoDic objectForKey:@"portraitImageLink"]]];
    
    dispatch_async(kBgQueue, ^{
        NSError* error = nil;
        NSData* data = [NSData dataWithContentsOfURL:url
                                             options:NSDataReadingUncached
                                               error:&error];//居然能如此简单！！！
        if (error) {
            NSLog(@"get portraitImage error:%@", error);
        } else
        {
            [self performSelectorOnMainThread:@selector(updatePortraitImage:)
                                   withObject:data
                                waitUntilDone:YES];
        }
    });
    
    self.name = [userInfoDic objectForKey:@"userName"];
    NSLog(@"%@", self.name);
    NSString *genderString = [userInfoDic objectForKey:@"gender"];
    self.gender = genderString.intValue;
    self.contact = [userInfoDic objectForKey:@"contact"];
    NSLog(@"%@", self.contact);
    self.signature = [userInfoDic objectForKey:@"signature"];
    NSLog(@"%@", self.signature);
    
    self.retrieved = YES;
    [self.tableView reloadData];
}

- (void)updatePortraitImage:(NSData *)data {
    NSLog(@"获得了头像准备刷新tableview");
    UIImage *tmpImage = [UIImage imageWithData:data];
    self.portraitImage = tmpImage;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0) {
        UserInfoCell *accountInfoCell = [tableView dequeueReusableCellWithIdentifier:@"UserInfoCell1"];
        if (self.retrieved) {
            accountInfoCell.accountPortraitImageView.image = self.portraitImage;
            accountInfoCell.accountNameLabel.text = self.name;
            if (self.gender == 0) {
                accountInfoCell.accountGenderImageView.image = [UIImage imageNamed:@"boy"];
            } else {
                accountInfoCell.accountGenderImageView.image = [UIImage imageNamed:@"girl"];
            }
            accountInfoCell.accountContactLabel.text = self.contact;
            accountInfoCell.accountSignatureLabel.text = self.signature;
        }
        return accountInfoCell;
    } else if (indexPath.row == 1) {
        SeparateCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserInfoCell2" forIndexPath:indexPath];
        return cell;
    } else {
        PostHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserInfoCell3" forIndexPath:indexPath];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    /// Here you can set also height according to your section and row
    if( indexPath.row==0 ) {
        return 200;
    } else if (indexPath.row == 1) {
        return 20;
    } else {
        return 44;
    }
}

@end
