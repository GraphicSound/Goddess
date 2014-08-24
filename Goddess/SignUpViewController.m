//
//  SignUpViewController.m
//  Goddess
//
//  Created by yu_hao on 4/9/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "SignUpViewController.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
#define serverUrl @"http://223.26.60.51/goddess"//2

@interface SignUpViewController ()
{
    AccountViewController *accountViewController;
}

@end

@implementation SignUpViewController

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
    
    //创建账户VC对象，已进行数据交换
    accountViewController = [AccountViewController sharedManager];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear...");
    [self checkLogin];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self.scrollView layoutIfNeeded];
    self.scrollView.contentSize = self.contentView.bounds.size;
    self.scrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    [self.scrollView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
}

- (void)checkLogin {
    if (!accountViewController.login) {
        //失败
        NSLog(@"您是首次登陆没有本地账号信息");
        [self.button2 setTitle:@"登陆" forState:UIControlStateNormal];
        [self.button1 setTitle:@"注册" forState:UIControlStateNormal];
        
        self.emailTextField.text = nil;
        self.passwordTextField.text = nil;
    } else {
        //读取token等信息成功
        NSLog(@"开始利用本地账号信息进行账号验证");
        self.emailTextField.text = accountViewController.email;
        self.passwordTextField.text = accountViewController.md5;
        
        [self.button2 setTitle:@"退出登录" forState:UIControlStateNormal];
        [self.button1 setTitle:@"" forState:UIControlStateNormal];
    }
}

- (IBAction)button1Action:(id)sender {
    NSString *email = self.emailTextField.text;
    NSString *password = self.passwordTextField.text;
    if (email.length == 0 || password.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"邮箱或密码不能为空"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    if (![email hasSuffix:@"@qq.com"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"邮箱格式不正确，请使用QQ邮箱"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    if (password.length < 6) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"密码应为六位或以上"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *registerDate = [formatter stringFromDate:date];
    
    NSString *registerString = [NSString stringWithFormat:@"%@/api.php?api=6&email=%@&password=%@&registerDate=%@", serverUrl, email, password, registerDate];
    NSURL *registerUrl = [NSURL URLWithString:[registerString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSError* error = nil;
    NSData* _responseData = [NSData dataWithContentsOfURL:registerUrl
                                         options:NSDataReadingUncached
                                           error:&error];//居然能如此简单！！！
    NSString *respondString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];  //现在是md5值
    NSLog(@"%@", respondString);
    
    if ([respondString isEqualToString:@"NO"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"该邮箱已注册!"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    } else
    {
        //存到本地
        NSArray *userInfoArrayFromRemoteJson = [NSJSONSerialization
                                                JSONObjectWithData:_responseData //1
                                                options:kNilOptions
                                                error:&error];
        if (error) {
            NSLog(@"数据有错");
            return;
        }
        NSDictionary *userInfoDic = [userInfoArrayFromRemoteJson objectAtIndex:0];
        
        NSDictionary *accountDic = [NSDictionary dictionaryWithObjectsAndKeys:[userInfoDic objectForKey:@"id"], @"userID", email, @"email", [userInfoDic objectForKey:@"md5"], @"md5", nil];
        NSData *accountData = [NSKeyedArchiver archivedDataWithRootObject:accountDic];
        NSString *pathK = [[NSBundle mainBundle] pathForResource:@"Authentication" ofType:nil];
        if([accountData writeToFile:pathK atomically:YES])
        {
            NSLog(@"账户数据写入本地文件成功");
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"注册成功!"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        accountViewController.login = YES;
        accountViewController.userIDString = [userInfoDic objectForKey:@"id"];
        accountViewController.email = email;
        accountViewController.md5 = respondString;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (IBAction)button2Action:(id)sender {
    if ([self.button2.titleLabel.text isEqualToString:@"登陆"]) {
        NSString *email = self.emailTextField.text;
        NSString *password = self.passwordTextField.text;
        if (email.length == 0 || password.length == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"邮箱或密码不能为空"
                                  
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
        if (![email hasSuffix:@"@qq.com"]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"邮箱格式不正确，请使用QQ邮箱"
                                  
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
        if (password.length < 6) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"密码应为六位或以上"
                                  
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
        
        NSDate *date = [[NSDate alloc] init];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
        NSString *registerDate = [formatter stringFromDate:date];
        
        NSString *registerString = [NSString stringWithFormat:@"%@/api.php?api=7&email=%@&password=%@&registerDate=%@", serverUrl, email, password, registerDate];
        NSURL *registerUrl = [NSURL URLWithString:[registerString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSError* error = nil;
        NSData* _responseData = [NSData dataWithContentsOfURL:registerUrl
                                                      options:NSDataReadingUncached
                                                        error:&error];//居然能如此简单！！！
        NSString *respondString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];  //现在是md5值
        NSLog(@"%@", respondString);
        
        if ([respondString isEqualToString:@"NO"]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"邮箱未注册"
                                  
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        } else
        {
            if ([respondString isEqualToString:@"INVALID"]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"密码不正确"
                                      
                                                               delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            } else {
                NSArray *userInfoArrayFromRemoteJson = [NSJSONSerialization
                                                JSONObjectWithData:_responseData //1
                                                options:kNilOptions
                                                error:&error];
                if (error) {
                    NSLog(@"数据有错");
                    return;
                }
                NSDictionary *userInfoDic = [userInfoArrayFromRemoteJson objectAtIndex:0];
                if ([userInfoDic objectForKey:@"portraitImageLink"] != nil) {
                    NSLog(@"有用户数据！！！");
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
                    
                    accountViewController.login = YES;
                    accountViewController.userIDString = [userInfoDic objectForKey:@"id"];
                    NSLog(@"%@", accountViewController.userIDString);
                    accountViewController.email = email;
                    NSLog(@"%@", accountViewController.email);
                    accountViewController.md5 = [userInfoDic objectForKey:@"md5"];
                    NSLog(@"%@", accountViewController.md5);
                    accountViewController.name = [userInfoDic objectForKey:@"userName"];
                    NSLog(@"%@", accountViewController.name);
                    NSString *genderString = [userInfoDic objectForKey:@"gender"];
                    accountViewController.gender = genderString.intValue;
                    accountViewController.contact = [userInfoDic objectForKey:@"contact"];
                    NSLog(@"%@", accountViewController.contact);
                    accountViewController.signature = [userInfoDic objectForKey:@"signature"];
                    NSLog(@"%@", accountViewController.signature);
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"登陆成功!"
                                          
                                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                    return;
                }
                //存到本地
                NSDictionary *accountDic = [NSDictionary dictionaryWithObjectsAndKeys:[userInfoDic objectForKey:@"id"], @"userID", email, @"email", [userInfoDic objectForKey:@"md5"], @"md5", nil];
                NSData *accountData = [NSKeyedArchiver archivedDataWithRootObject:accountDic];
                NSString *pathK = [[NSBundle mainBundle] pathForResource:@"Authentication" ofType:nil];
                if([accountData writeToFile:pathK atomically:YES])
                {
                    NSLog(@"账户数据写入本地文件成功");
                }
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"登陆成功!"
                                      
                                                               delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                accountViewController.login = YES;
                accountViewController.userIDString = [userInfoDic objectForKey:@"id"];
                accountViewController.email = email;
                accountViewController.md5 = [userInfoDic objectForKey:@"md5"];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }
    }
    
    if ([self.button2.titleLabel.text isEqualToString:@"退出登录"]) {
        NSLog(@"开始退出登录");
        self.emailTextField.text = nil;
        self.passwordTextField.text = nil;
        
        NSData *tmpData = [NSData new];
        NSString *pathK = [[NSBundle mainBundle] pathForResource:@"Authentication" ofType:nil];
        if([tmpData writeToFile:pathK atomically:YES])
        {
            NSLog(@"清除登陆信息成功");
        }
        [accountViewController readAccountDataFromFile];
    }
}

- (void)updatePortraitImage:(NSData *)data {
    UIImage *portraitImage = [UIImage imageWithData:data];
    accountViewController.portraitImage = portraitImage;
    //存到本地
    NSDictionary *accountDic = [NSDictionary dictionaryWithObjectsAndKeys:accountViewController.userIDString, @"userID",accountViewController.email, @"email", accountViewController.md5, @"md5", accountViewController.portraitImage, @"portraitImage", accountViewController.name, @"name", [NSString stringWithFormat:@"%d", accountViewController.gender], @"gender", accountViewController.contact, @"contact", accountViewController.signature, @"signature", nil];
    NSData *accountData = [NSKeyedArchiver archivedDataWithRootObject:accountDic];
    NSString *pathK = [[NSBundle mainBundle] pathForResource:@"Authentication" ofType:nil];
    if([accountData writeToFile:pathK atomically:YES])
    {
        NSLog(@"登陆：账户数据写入本地文件成功");
    } else {
        NSLog(@"登陆：账户数据写入本地文件失败");
    }
    NSLog(@"开始在main queue上刷新UI");
    [accountViewController.accountTableView reloadData];
}

@end
