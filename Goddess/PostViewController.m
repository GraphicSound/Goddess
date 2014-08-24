//
//  ViewController.m
//  Godess
//
//  Created by yu_hao on 3/12/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "PostViewController.h"

//#define kGETUrl @"http://www.dolphinwheel.com/"
//#define kGETUrl @"http://192.168.191.3"
//#define kGETUrl @"http://118.228.173.120/goddess"
#define serverUrl @"http://223.26.60.51/goddess" //2

@interface PostViewController ()
{
    AccountViewController *accountViewController;
    NSMutableData *_responseData;
    NSMutableArray *imageArray;
    NSMutableArray *imageViewArray;
    NSString *userIDString;
    NSString *accountName;
    NSString *deviceName;
    NSString *systemNameAndVersion;
    int activeType;
    UIButton *activeButton;
}

@end

@implementation PostViewController

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self.scrollView layoutIfNeeded];
    self.scrollView.contentSize = self.contentView.bounds.size;
    self.scrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    [self.scrollView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    self.collectionViewHeightConstraint.constant = self.collectionView.contentSize.height;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.contentView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
    
    //创建账户VC对象，已进行数据交换
    accountViewController = [AccountViewController sharedManager];
    accountName = accountViewController.name;
    NSLog(@"accountName:%@", accountName);
    if (accountName == nil) {
        accountName = @"花姑娘";
    }
    
    userIDString = accountViewController.userIDString;
    deviceName = [[UIDevice currentDevice] name];
    systemNameAndVersion = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
    
    //初始化type
    activeType = 1;
    activeButton = self.typeButton1;
    [activeButton setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    
    imageArray = [NSMutableArray new];
    [self.textView setTextContainerInset:UIEdgeInsetsMake(8, 4, 0, 0)];
    self.textView.placeholder = @"说点什么吧...";
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    self.collectionViewHeightConstraint.constant = 85;  //没有用
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.collectionView reloadData];
}

- (IBAction)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma UICollectionView protocal

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    if (imageArray.count == 0) {
        return 1;
    }
    return imageArray.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionCell" forIndexPath:indexPath];
    UIImageView *tmpImageView = (UIImageView*)[cell viewWithTag:100];
    if (imageArray.count == 0) {
        tmpImageView.image = [UIImage imageNamed:@"selectImageIcon"];
    } else {
        tmpImageView.image = [imageArray objectAtIndex:indexPath.row];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    [self pickImage:self];
}

#pragma mark select images part

- (void)pickImage:(id)sender {
    ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
    
    elcPicker.maximumImagesCount = 6;
    
    elcPicker.returnsOriginalImage = NO; //Only return the fullScreenImage, not the fullResolutionImage
    
	elcPicker.imagePickerDelegate = self;
    
    [self presentViewController:elcPicker animated:YES completion:nil];
}

#pragma mark ELCImagePickerControllerDelegate Methods

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    imageArray = [NSMutableArray arrayWithCapacity:[info count]];
	
	for (NSDictionary *dict in info) {
        
        UIImage *image = [dict objectForKey:UIImagePickerControllerOriginalImage];
        
        [imageArray addObject:image];
	}
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark post header settings

- (IBAction)setActiveTypeButton:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (button != activeButton) {
        [activeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        activeButton = button;
        [activeButton setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        activeType = [activeButton tag];
        
        NSLog(@"active button now is %d", [activeButton tag]);
    }
}

//用来往http header里面添加string信息的函数
- (void)addString:(NSString *)string byName:(NSString *)name toBodyData:(NSMutableData *)body withBoundary:(NSString *)boundary {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", name] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", string] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)post:(id)sender {
    /*
     NSMutableString *dataUrl = [[NSMutableString alloc] init];
     [dataUrl appendString:kGETUrl];
     [dataUrl appendString:[NSString stringWithFormat:@"entry.php?text=%@&image_source=%@", self.text.text, self.image_source.text]];
     dataUrl = (NSMutableString *)[dataUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
     
     NSLog(@"%@", self.text.text);
     NSLog(@"%@", self.image_source.text);
     NSLog(@"%@", dataUrl);
     
     // Create the request.
     NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:dataUrl]];
     
     // Create url connection and fire request
     NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
     
     if ([imageArray count] == 0) {
     NSLog(@"imageArray is empty, please select some images");
     return;
     }
     */
    if (!accountViewController.login) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"您尚未登录"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSMutableString *dataUrl = [[NSMutableString alloc] init];
    [dataUrl appendString:serverUrl];
    [dataUrl appendString:[NSString stringWithFormat:@"/upload.php"]];
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
    
    // Now append the image
    // Note that the name of the form field is exactly the same as in the trace ('attachment[file]' in my case)!
    // You can choose whatever filename you want.
    NSString *autoNameByDate = nil;
    
    NSDate *date = [[NSDate alloc] init];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    
    autoNameByDate = [formatter stringFromDate:date];
    
    int imageNumber = 0;
    
    for (UIImage *image in imageArray) {
        NSLog(@"image %d", imageNumber);
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%d\";filename=\"%@-%@-%d.jpg\"\r\n", imageNumber, autoNameByDate, deviceName, imageNumber] dataUsingEncoding:NSUTF8StringEncoding]];
        
        // We now need to tell the receiver what content type we have
        // In my case it's a png image. If you have a jpg, set it to 'image/jpg'
        [body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Now we append the actual image data
        NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
        
        [body appendData:[NSData dataWithData:imageData]];
        
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        imageNumber++;
    }
    
    // and again the delimiting boundary
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
    /*
     [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
     [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"deviceName\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
     [body appendData:[[NSString stringWithFormat:@"%@\r\n", deviceName] dataUsingEncoding:NSUTF8StringEncoding]];
     */
    
    //先放类型吧
    [self addString:[NSString stringWithFormat:@"%d", activeType] byName:@"type" toBodyData:body withBoundary:boundary];
    
    //userID
    [self addString:[NSString stringWithFormat:@"%d", userIDString.intValue] byName:@"userID" toBodyData:body withBoundary:boundary];
    
    //把content文字内容放到数据头里面
    [self addString:self.textView.text byName:@"content" toBodyData:body withBoundary:boundary];
    
    //视频地址
    [self addString:self.videoLinkTextField.text byName:@"videoLink" toBodyData:body withBoundary:boundary];
    
    //把账户名称放进body
    [self addString:accountName byName:@"accountName" toBodyData:body withBoundary:boundary];
    
    //把设备名称放进body
    [self addString:deviceName byName:@"deviceName" toBodyData:body withBoundary:boundary];
    
    //把系统版本放进body
    [self addString:systemNameAndVersion byName:@"systemNameAndVersion" toBodyData:body withBoundary:boundary];
    
    //最后放上系统时间
    [self addString:autoNameByDate byName:@"postDate" toBodyData:body withBoundary:boundary];
    
    
    
    [request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
	
    // adding the body we've created to the request
    [request setHTTPBody:body];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
                                                                  delegate:self
                                                          startImmediately:YES];
    
    //    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:@"myapp.run_mode"];
    //    [connection start];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
    NSString *respondString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", respondString);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"connection did finish loading");
    
    //成功的话，我们暂时就隐藏VC
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@",[error localizedDescription]);
}

@end
