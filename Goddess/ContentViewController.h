//
//  ContentViewController.h
//  Godess
//
//  Created by yu_hao on 3/27/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentCell.h"
#import "UserInfoViewController.h"
#import "AccountViewController.h"
#import "CommentCell.h"
#import "TPKeyboardAvoidingTableView.h"
#import <objc/runtime.h>

#import "sqlite3.h"

@interface ContentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, ContentCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

+ (ContentViewController *)sharedManager;   //暂时没用

- (void)createDatabase;
- (void)retrieveImages:(NSArray *)imageLinksArray forCell:(ContentCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)checkUpdate;
- (void)getLocalMaxPostID;
- (void)getRemoteMaxPostID;
- (void)savePostsDataToDatabase:(NSDictionary *)responseDic;
- (void)readPostsDataFromLocalDatabase;
- (IBAction)reload:(id)sender;
- (IBAction)drop:(id)sender;

- (BOOL)sendComment:(NSString *)comment byIndex:(int)index;

@end
