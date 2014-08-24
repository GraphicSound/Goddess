//
//  ViewController.h
//  Godess
//
//  Created by yu_hao on 3/12/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIPlaceHolderTextView.h"
#import "ELCImagePickerController.h"
#import "AccountViewController.h"

@interface PostViewController : UIViewController <NSURLConnectionDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate, ELCImagePickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *videoLinkTextField;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

- (IBAction)dismissViewController:(id)sender;

- (IBAction)setActiveTypeButton:(id)sender;

- (void)pickImage:(id)sender;

- (IBAction)post:(id)sender;

- (void)addString:(NSString *)string byName:(NSString *)name toBodyData:(NSMutableData *)body withBoundary:(NSString *)boundary;

@property (weak, nonatomic) IBOutlet UIButton *typeButton2;
@property (weak, nonatomic) IBOutlet UIButton *typeButton5;
@property (weak, nonatomic) IBOutlet UIButton *typeButton1;
@property (weak, nonatomic) IBOutlet UIButton *typeButton3;
@property (weak, nonatomic) IBOutlet UIButton *typeButton4;
@property (weak, nonatomic) IBOutlet UIButton *typeButton6;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;

@end
