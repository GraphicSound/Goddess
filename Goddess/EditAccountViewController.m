//
//  EditAccountViewController.m
//  Goddess
//
//  Created by yu_hao on 4/8/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "EditAccountViewController.h"

#define serverUrl @"http://223.26.60.51/goddess"//2

@interface EditAccountViewController ()
{
    AccountViewController *accountViewController;
    NSMutableData *_responseData;
    bool succeed;
    
    NSString *name;
    int gender;
    NSString *contact;
    NSString *signature;
    UIImage *portraitImage;
}

@end

@implementation EditAccountViewController

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
    
    self.contactTextView.placeholder = @"留下你的联系方式...";
    self.signatureTextView.placeholder = @"介绍一下自己...";
}

- (void)viewWillAppear:(BOOL)animated {
    if (accountViewController.contact != nil || ![accountViewController.contact isEqualToString:@""]) {
        //self.portraitImageView.image = accountViewController.portraitImage;
        self.nameTextField.text = accountViewController.name;
        [self.genderSegmentedControl setSelectedSegmentIndex:accountViewController.gender];
        self.contactTextView.text = accountViewController.contact;
        self.signatureTextView.text = accountViewController.signature;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self.scrollView layoutIfNeeded];
    self.scrollView.contentSize = self.contentView.bounds.size;
    self.scrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    [self.scrollView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
}

- (IBAction)selectPortraitImage:(id)sender {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    self.portraitImageView.image = image;
    portraitImage = image;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//用来往http header里面添加string信息的函数
- (void)addString:(NSString *)string byName:(NSString *)aName toBodyData:(NSMutableData *)body withBoundary:(NSString *)boundary {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", aName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", string] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)updateAccountInfo:(id)sender {
    if (!accountViewController.login) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"您还没有登陆"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    name = self.nameTextField.text;
    gender = (int)self.genderSegmentedControl.selectedSegmentIndex;
    contact = self.contactTextView.text;
    signature = self.signatureTextView.text;
    if (portraitImage == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"请上传一张头像"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    if ([name isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"请告诉大家你的名字"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    if ([contact isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"请告诉大家你的联系方式"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    if ([signature isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"请写一句话简单介绍一下自己"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSMutableString *dataUrl = [[NSMutableString alloc] init];
    [dataUrl appendString:serverUrl];
    [dataUrl appendString:[NSString stringWithFormat:@"/api.php?api=8"]];
    dataUrl = (NSMutableString *)[dataUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"%@", dataUrl);
    
    //为什么要用mutable request？
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:dataUrl]
                                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:60];
    
    [request setHTTPMethod:@"POST"];
    
    // We need to add a header field named Content-Type with a value that tells that it's a form and also add a boundary.
    // I just picked a boundary by using one from a previous trace, you can just copy/paste from the traces.
    NSString *boundary = @"WebKitFormBoundarycC4YiaUFwM44F6rT";
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    // end of what we've added to the header
    
    // the body of the post
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"0\";filename=\"%@.jpg\"\r\n", accountViewController.userIDString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // We now need to tell the receiver what content type we have
    // In my case it's a png image. If you have a jpg, set it to 'image/jpg'
    [body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Now we append the actual image data
    NSData *imageData = UIImageJPEGRepresentation(portraitImage, 0.6);
    
    [body appendData:[NSData dataWithData:imageData]];
    
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // and again the delimiting boundary
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self addString:accountViewController.email byName:@"email" toBodyData:body withBoundary:boundary];
    NSLog(@"%@", accountViewController.email);
    
    [self addString:accountViewController.md5 byName:@"md5" toBodyData:body withBoundary:boundary];
    NSLog(@"%@", accountViewController.md5);
    
    [self addString:name byName:@"name" toBodyData:body withBoundary:boundary];
    
    [self addString:[NSString stringWithFormat:@"%d", gender] byName:@"gender" toBodyData:body withBoundary:boundary];
    
    [self addString:contact byName:@"contact" toBodyData:body withBoundary:boundary];
    
    [self addString:signature byName:@"signature" toBodyData:body withBoundary:boundary];
    
    [request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
	
    // adding the body we've created to the request
    [request setHTTPBody:body];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
                                                                  delegate:self
                                                          startImmediately:YES];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
    NSString *respondString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", respondString);
    if ([respondString hasSuffix:@"YES"]) {
        succeed = YES;
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    NSLog(@"connection did finish loading");
    
    //成功的话，我们暂时就隐藏VC
    if (succeed) {
        accountViewController.name = name;
        accountViewController.gender = gender;
        accountViewController.contact = contact;
        accountViewController.signature = signature;
        accountViewController.portraitImage = portraitImage;
        
        //存到本地
        NSDictionary *accountDic = [NSDictionary dictionaryWithObjectsAndKeys:accountViewController.userIDString, @"userID", accountViewController.email, @"email", accountViewController.md5, @"md5", portraitImage, @"portraitImage", name, @"name", [NSString stringWithFormat:@"%d", gender], @"gender", contact, @"contact", signature, @"signature", nil];
        NSData *accountData = [NSKeyedArchiver archivedDataWithRootObject:accountDic];
        NSString *pathK = [[NSBundle mainBundle] pathForResource:@"Authentication" ofType:nil];
        if([accountData writeToFile:pathK atomically:YES])
        {
            NSLog(@"账户数据写入本地文件成功");
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"%@",[error localizedDescription]);
}

@end
