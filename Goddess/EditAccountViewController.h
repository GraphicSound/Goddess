//
//  EditAccountViewController.h
//  Goddess
//
//  Created by yu_hao on 4/8/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIPlaceHolderTextView.h"
#import "AccountViewController.h"

@interface EditAccountViewController : UIViewController <NSURLConnectionDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSegmentedControl;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *contactTextView;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *signatureTextView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

- (IBAction)selectPortraitImage:(id)sender;
- (IBAction)dismissViewController:(id)sender;
- (IBAction)updateAccountInfo:(id)sender;

- (void)addString:(NSString *)string byName:(NSString *)name toBodyData:(NSMutableData *)body withBoundary:(NSString *)boundary;

@end
