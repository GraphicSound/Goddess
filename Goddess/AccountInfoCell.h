//
//  AccountInfoCell.h
//  Goddess
//
//  Created by yu_hao on 3/31/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *accountPortraitImageView;
@property (weak, nonatomic) IBOutlet UILabel *accountNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *accountGenderImageView;
@property (weak, nonatomic) IBOutlet UILabel *accountContactLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountSignatureLabel;

@property (weak, nonatomic) IBOutlet UILabel *contactLabel;
@property (weak, nonatomic) IBOutlet UILabel *signatureLabel;

@property (weak, nonatomic) IBOutlet UIView *tmpView;
@property (weak, nonatomic) IBOutlet UIImageView *tmpImageView;
@property (weak, nonatomic) IBOutlet UILabel *tmpLabel;

@end
