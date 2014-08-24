//
//  ClassroomViewController.m
//  Goddess
//
//  Created by yu_hao on 4/14/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "ClassroomViewController.h"

@interface ClassroomViewController ()

@end

@implementation ClassroomViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib {
    self.title = @"教室情缘";
    self.array1 = [NSArray arrayWithObjects:@"一教", @"二教", nil];
    self.array2 = [NSArray arrayWithObjects:@"一楼", @"二楼", @"三楼", @"四楼", @"五楼", @"六楼", nil];
    self.array3 = [NSArray arrayWithObjects:@"一教室", @"二教室", @"三教室", @"四教室", @"五教室", @"六教室", @"七教室", nil];
}

- (void)viewWillAppear:(BOOL)animated {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    int index1 = (int)(self.array1.count-1)/2;
    int index2 = (int)(self.array2.count-1)/2;
    int index3 = (int)(self.array3.count-1)/2;
    
    [self.pickerView1 selectRow:index1 inComponent:0 animated:YES];
    [self.pickerView2 selectRow:index2 inComponent:0 animated:YES];
    [self.pickerView3 selectRow:index3 inComponent:0 animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
{
    if (pickerView.tag == 1) {
        return self.array1.count;
    } else if (pickerView.tag == 2) {
        return self.array2.count;
    } else {
        return self.array3.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
{
    if (pickerView.tag == 1) {
        return [self.array1 objectAtIndex:row];
    } else if (pickerView.tag == 2) {
        return [self.array2 objectAtIndex:row];
    } else {
        return [self.array3 objectAtIndex:row];
    }
}

@end
