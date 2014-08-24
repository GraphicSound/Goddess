//
//  ClassroomViewController.h
//  Goddess
//
//  Created by yu_hao on 4/14/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClassroomViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView1;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView2;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView3;

@property NSArray *array1;
@property NSArray *array2;
@property NSArray *array3;

@end
