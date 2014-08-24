//
//  AccountViewController.m
//  Goddess
//
//  Created by yu_hao on 3/31/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "AccountViewController.h"
#import "AccountInfoCell.h"
#import "SeparateCell.h"
#import "GoToPostCell.h"
#import "PostHistoryCell.h"

@interface AccountViewController ()
{
    SignUpViewController *signUpViewController;
    EditAccountViewController *editAccountViewController;
    AccountInfoCell *accountInfoCell;
    UIView *UserInfoNib;
}

@end

@implementation AccountViewController

@synthesize login = login;

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
    NSLog(@"AccountViewController did load...");
}

- (void)awakeFromNib {
    self.title = @"个人中心";
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSLog(@"AccountViewController initWithCoder...");
        login = NO;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        signUpViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];
        editAccountViewController = [storyboard instantiateViewControllerWithIdentifier:@"EditAccountViewController"];
        [self readAccountDataFromFile];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear...");
    [self.accountTableView reloadData];
}

static AccountViewController * SharedViewController=nil;

+ (AccountViewController *)sharedManager {
    @synchronized(self)
    {
        if(!SharedViewController)
        {
            SharedViewController = [[super allocWithZone:NULL] init];
            //SharedViewController = [[ViewController alloc] init];
        }
    }
    return SharedViewController;
}

+ (id) allocWithZone:(NSZone *) zone {
    @synchronized(self) {
        if (SharedViewController == nil) {
            SharedViewController = [super allocWithZone:zone];
            return SharedViewController;
        }
    }
    return nil;
}

- (void)readAccountDataFromFile {
    NSString *pathK = [[NSBundle mainBundle] pathForResource:@"Authentication" ofType:nil];
    NSData *dataFromFile = [NSData dataWithContentsOfFile:pathK];
    NSDictionary *dataDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:dataFromFile];
    if (dataDictionary == nil || [dataDictionary objectForKey:@"email"] == nil) {
        //重置变量
        NSLog(@"您是首次登陆没有本地账号信息");
        login = NO;
        self.userIDString = nil;
        self.email = nil;
        self.md5 = nil;
        self.name = nil;
        self.contact = nil;
        self.signature = nil;
        
    } else {
        //读取token等信息成功
        NSLog(@"开始利用本地账号信息进行账号验证");
        login = YES;
        self.userIDString = [dataDictionary objectForKey:@"userID"];
        NSLog(@"我的ID是%d", self.userIDString.intValue);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:[NSString stringWithFormat:@"我的ID是%d", self.userIDString.intValue]
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        self.email = [dataDictionary objectForKey:@"email"];
        self.md5 = [dataDictionary objectForKey:@"md5"];
        self.portraitImage = [dataDictionary objectForKey:@"portraitImage"];
        self.name = [dataDictionary objectForKey:@"name"];
        NSString *genderString = [dataDictionary objectForKey:@"gender"];
        self.gender = genderString.intValue;
        self.contact = [dataDictionary objectForKey:@"contact"];
        self.signature = [dataDictionary objectForKey:@"signature"];
        [self.accountTableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSLog(@"cellForRowAtIndexPath is called...");
    
    if (indexPath.row == 0) {
        accountInfoCell = [self.accountTableView dequeueReusableCellWithIdentifier:@"cell1"];
        if (login) {
            NSLog(@"已登录，显示个人信息UI");
            NSLog(@"取消tmp显示");
            accountInfoCell.tmpImageView.image = nil;
            accountInfoCell.tmpLabel.text = nil;
            [accountInfoCell.tmpView removeFromSuperview];
            accountInfoCell.tmpView = nil;
            
            //如果各个变量已经有了值，表明由用户信息，需要显示
            if (self.name != nil || [self.name isEqualToString:@""]) {
                NSLog(@"恭喜你，有详细信息");
                accountInfoCell.accountPortraitImageView.image = self.portraitImage;
                accountInfoCell.accountNameLabel.text = self.name;
                if (self.gender == 0) {
                    accountInfoCell.accountGenderImageView.image = [UIImage imageNamed:@"boy"];
                } else {
                    accountInfoCell.accountGenderImageView.image = [UIImage imageNamed:@"girl"];
                }
                accountInfoCell.accountContactLabel.text = self.contact;
                accountInfoCell.accountSignatureLabel.text = self.signature;
                
                accountInfoCell.contactLabel.text = @"联系方式";
                accountInfoCell.signatureLabel.text = @"个人介绍";
                return accountInfoCell;
            } else {
                NSLog(@"还没有详细信息");
                accountInfoCell.accountPortraitImageView.image = [UIImage imageNamed:@"portraitImagePlaceholder"];
                accountInfoCell.accountNameLabel.text = @"花姑娘";
                accountInfoCell.accountContactLabel.text = @"点击完善";
                accountInfoCell.accountSignatureLabel.text = @"点击完善";
                
                accountInfoCell.contactLabel.text = @"联系方式";
                accountInfoCell.signatureLabel.text = @"个人介绍";
                return accountInfoCell;
            }
        } else {
            NSLog(@"提示用户注册");
            accountInfoCell.accountPortraitImageView.image = nil;
            accountInfoCell.accountGenderImageView.image = nil;
            accountInfoCell.accountNameLabel.text = nil;
            accountInfoCell.accountContactLabel.text = nil;
            accountInfoCell.accountSignatureLabel.text = nil;
            
            accountInfoCell.contactLabel.text = nil;
            accountInfoCell.signatureLabel.text = nil;
            
            accountInfoCell.tmpImageView.image = [UIImage imageNamed:@"appIcon"];
            accountInfoCell.tmpLabel.text = @"快登陆吧";
            
            //UserInfoNib = [[[NSBundle mainBundle] loadNibNamed:@"UserInfoNib" owner:nil options:nil] lastObject];
            //[accountInfoCell addSubview:UserInfoNib];
        }
        return accountInfoCell;
    } else if (indexPath.row == 1) {
        SeparateCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell2" forIndexPath:indexPath];
        return cell;
    } else if (indexPath.row == 2) {
        GoToPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell3" forIndexPath:indexPath];
        return cell;
    } else if (indexPath.row == 3){
        SeparateCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell4" forIndexPath:indexPath];
        return cell;
    } else {
        PostHistoryCell *postHistoryCell = [tableView dequeueReusableCellWithIdentifier:@"cell5" forIndexPath:indexPath];
        return postHistoryCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    /// Here you can set also height according to your section and row
    if( indexPath.row==0 ) {
        return 200;
    } else if (indexPath.row == 1 || indexPath.row == 3) {
        return 20;
    } else if (indexPath.row == 2) {
        return 80;
    } else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0) {
        if (!login) {
            NSLog(@"显示注册界面");
            //[self presentViewController:signUpViewController animated:YES completion:nil];
            [self.navigationController pushViewController:signUpViewController animated:YES];
        } else {
            [self presentViewController:editAccountViewController animated:YES completion:nil];
        }
    }
}

- (IBAction)test:(id)sender {
    [self.accountTableView reloadData];
}

@end
