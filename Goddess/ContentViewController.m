//
//  ContentViewController.m
//  Godess
//
//  Created by yu_hao on 3/27/14.
//  Copyright (c) 2014 yu_hao. All rights reserved.
//

#import "ContentViewController.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
//#define serverUrl [NSURL URLWithString:@"http://192.168.191.3"] //2
//#define serverUrl @"http://118.228.173.120/goddess" //2
#define serverUrl @"http://223.26.60.51/goddess"//2

@interface ContentViewController ()
{
    AccountViewController *accountViewController;
    
    NSFileManager *_filemgr;
    
    sqlite3 *_database;
    NSString *_databasePath;
    int localMaxPostID;
    int remoteMaxPostID;
    int localMaxCommentID;
    int remoteMaxCommentID;
    bool existUpdate;
    
    ContentCell *cellForHeight;
    NSArray *_postsArrayFromRemoteJson;
    NSMutableArray *_postsArrayFromLocalDatabase;
    NSArray *_commentsArrayFromRemoteJson;
    NSMutableDictionary *_commentsDicFromLocalDatabase;
    NSMutableArray *_commentsArrayForCurrentContentCell;
    NSMutableDictionary *_dicForImage;  //this baby will keeps growing up but never be recreated
    NSMutableDictionary *_dicForLoadingImage;
    NSMutableDictionary *_dicForImageLinksArray;
    
    NSMutableDictionary *_dicForCellHeight;
    bool heightNeedRecalculate;
    
    UITapGestureRecognizer* tgr;
    UIImageView *fullScreenImageView;
    int currentPostID;  //also the collection view tag
    int currentImageIndex;
    
    int userIDForUsrInfo;
}

@end

@implementation ContentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib {
    self.title = @"空间";
}

static ContentViewController * SharedViewController=nil;

+ (ContentViewController *)sharedManager {
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //创建账户VC对象，已进行数据交换
    accountViewController = [AccountViewController sharedManager];
    
    _filemgr = [NSFileManager defaultManager];
    
    //准备数据库
    //NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    //_databasePath = [[NSString alloc] initWithString: [bundlePath stringByAppendingPathComponent:@"database.db"]];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tmpString = [dirPaths objectAtIndex:0];
    _databasePath = [[NSString alloc] initWithString: [tmpString stringByAppendingPathComponent:@"database.db"]];
    
    NSLog(@"数据库路径:%@", _databasePath);
    if ([_filemgr fileExistsAtPath: _databasePath ] == NO)
    {
        [self createDatabase];
    } else {
        NSLog(@"数据库已存在");
    }
    [self checkUpdate];  //这个因为是在别的进程上，所以有点不同步，导致在这里打印remoteMaxPostID会是0
    
    //暂时放在这里，，，非登录部分
    _postsArrayFromRemoteJson = [NSArray new];
    _postsArrayFromLocalDatabase = [NSMutableArray new];
    _commentsArrayFromRemoteJson = [NSArray new];
    _commentsDicFromLocalDatabase = [NSMutableDictionary new];
    _commentsArrayForCurrentContentCell = [NSMutableArray new];
    _dicForImage = [NSMutableDictionary new];
    _dicForLoadingImage = [NSMutableDictionary new];
    _dicForImageLinksArray = [NSMutableDictionary new];
    _dicForCellHeight = [NSMutableDictionary new];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"!!!!!!!!!!!didReceiveMemoryWarning!!!!!!!!!!!!!!!");
}

- (void)showUserInfoViewControllerByUserID:(int)userID {
    NSLog(@"showUserInfoViewControllerByUserID %d", userID);
    userIDForUsrInfo = userID;
    [self performSegueWithIdentifier:@"UserInfoViewControllerSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"UserInfoViewControllerSegue"]){
        UserInfoViewController *userInfoViewController = segue.destinationViewController;
        userInfoViewController.userID = userIDForUsrInfo;
        NSLog(@"prepareForSegue %d", userInfoViewController.userID);
    }
}

#pragma mark UI tableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    if (tableView.tag == 99) {
        NSLog(@"一共有%d条post用于显示", [_postsArrayFromLocalDatabase count]);
        return [_postsArrayFromLocalDatabase count];
    } else {
        NSLog(@"一共有%d条评论用于显示", [_commentsArrayForCurrentContentCell count]);
        return [_commentsArrayForCurrentContentCell count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (tableView.tag == 99) {
        NSLog(@"post tableview...");
        ContentCell *contentCell = [tableView dequeueReusableCellWithIdentifier:@"ContentCell" forIndexPath:indexPath];
        
        contentCell.delegate = self;
        
        // Configure the cell...
        NSDictionary *dicFromJson = [_postsArrayFromLocalDatabase objectAtIndex:indexPath.row];
        NSString *postIDString = [dicFromJson objectForKey:@"postID"];
        int postID = postIDString.intValue;
        NSString *userIDString = [dicFromJson objectForKey:@"userID"];
        int userID = userIDString.intValue;
        [contentCell.portraitImageView setTag:userID];
        [contentCell.collectionView setTag:indexPath.row];
        [contentCell.commentTableView setTag:postID];
        [contentCell.commentTextField setTag:indexPath.row];   //巧妙地将post数据传到了对应的textfield
        
        contentCell.portraitImageView.image = nil;
        if ([_dicForImage objectForKey:[NSString stringWithFormat:@"%d.jpg", userID]] != nil) {
            contentCell.portraitImageView.image = [_dicForImage objectForKey:[NSString stringWithFormat:@"%d.jpg", userID]];
        }
        
        contentCell.nameLabel.text = [dicFromJson objectForKey:@"userName"];
        contentCell.contentLabel.text = [dicFromJson objectForKey:@"content"];
        contentCell.systemNameAndVersionLabel.text = [dicFromJson objectForKey:@"systemNameAndVersion"];
        NSString *type = [dicFromJson objectForKey:@"type"];
        switch (type.intValue) {
            case 1:
                type = @"找女神";
                break;
            case 2:
                type = @"分享女神";
                break;
            case 3:
                type = @"我是女神";
                break;
            case 4:
                type = @"求女神";
                break;
            case 5:
                type = @"求男神";
                break;
            case 6:
                type = @"求好友";
                break;
            case 7:
                type = @"nil";
                break;
                
            default:
                type = @"未定义";
                break;
        }
        contentCell.typeLabel.text = type;
        
        NSString *imageLinks = [dicFromJson objectForKey:@"imageLinks"];
        NSArray *imageLinksArray = [imageLinks componentsSeparatedByString:@";"];   //这里应该是最后一个分号多分了一个，数组最后一个是nil
        NSLog(@"table view解析出%d张图片", imageLinksArray.count -1);
        [_dicForImageLinksArray setObject:imageLinksArray forKey:[NSString stringWithFormat:@"%d", indexPath.row]];
        [contentCell.collectionView reloadData];
        
        NSMutableArray *imageLinksArrayWithPortrait = [NSMutableArray arrayWithArray:imageLinksArray];
        NSString *portraitImageLinkString = [NSString stringWithFormat:@"%d.jpg", userID];
        [imageLinksArrayWithPortrait insertObject:portraitImageLinkString atIndex:0];
        //if (imageLinksArray.count > 1) {
            //在另一进程联网拉去图片,,,但是这样与main queue就不同步了！图片不会在获取后得到更新，除非，，，除非赶在return之前？还是在cache里时候？
            //不用的话，又怎么保证用户交互相应？？？？
            //dispatch_async(kBgQueue, ^{
            [self retrieveImages:imageLinksArrayWithPortrait forCell:contentCell atIndexPath:indexPath];
            //});
        //}
        
        //刷新内置的评论tableview
        //[self prepareCommentArrayForPost:postID];
        _commentsArrayForCurrentContentCell = [_commentsDicFromLocalDatabase objectForKey:[NSString stringWithFormat:@"%d", postID]];
        NSLog(@"手动刷新评论");
        NSLog(@"this post has %d comments...", _commentsArrayForCurrentContentCell.count);
        [contentCell.commentTableView reloadData];
        
        //很重要，别忘了
        contentCell.commentTextField.text = @"";
        
        return contentCell;
    } else {
        NSLog(@"refresh comment tableview...");
        CommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell" forIndexPath:indexPath];
        NSArray *tmpCommentArray = [_commentsDicFromLocalDatabase objectForKey:[NSString stringWithFormat:@"%d", tableView.tag]];
        NSLog(@"tag is:%d", tableView.tag);
        
        //tableview奇怪的机制，必须先检查一下是否越界
        if (tmpCommentArray != nil) {
            if (tmpCommentArray.count > indexPath.row) {
                NSMutableDictionary *tmpDic = [tmpCommentArray objectAtIndex:indexPath.row];
                commentCell.commentUserNameLabel.text = [tmpDic objectForKey:@"userName"];
                commentCell.commentLabel.text = [tmpDic objectForKey:@"comment"];
            } else {
                NSLog(@"------越界了！！！");
            }
        } else {
            NSLog(@"tableview没有找到对应的array");
        }
        
        return commentCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 99) {
        if (!cellForHeight) {
            cellForHeight = [tableView dequeueReusableCellWithIdentifier:@"ContentCell"];
        }
        
        //configure the cell
        NSDictionary *dicFromJson = [_postsArrayFromLocalDatabase objectAtIndex:indexPath.row];
        NSString *tmpPostID = [dicFromJson objectForKey:@"postID"];
        if ([_dicForCellHeight objectForKey:tmpPostID] == nil || heightNeedRecalculate) {
            cellForHeight.nameLabel.text = @"userName";   //这里随便，因为反正高度都固定
            cellForHeight.contentLabel.text = [dicFromJson objectForKey:@"content"];
            cellForHeight.systemNameAndVersionLabel.text = @"systemNameAndVersion";
            cellForHeight.typeLabel.text = @"type";
            
            cellForHeight.collectionViewHeightConstraint.constant = 78;
            
            //这里记住constraint要是greater than or equal的类型
            NSString *postIDString = [dicFromJson objectForKey:@"postID"];
            NSArray *tmpCommentArray = [_commentsDicFromLocalDatabase objectForKey:postIDString];
            int commentsCount = tmpCommentArray.count;
            cellForHeight.commentViewHeightConstraint.constant = 30 + 8 + 25.0 * commentsCount;
            
            //layout the cell
            [cellForHeight layoutIfNeeded];
            NSLog(@"heightForRowAtIndexPath:layoutIfNeeded...");
            
            // Get the actual height required for the cell
            CGFloat height = [cellForHeight.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            
            // Add an extra point to the height to account for the cell separator, which is added between the bottom
            // of the cell's contentView and the bottom of the table view cell.
            height += 1;
            
            [_dicForCellHeight setObject:[NSString stringWithFormat:@"%f", height] forKey:tmpPostID];
            return height;
        } else {
            NSLog(@"!!!!!!!!YEAH, WE GOT HEIGHT...");
            NSString *heightString = [_dicForCellHeight objectForKey:tmpPostID];
            CGFloat height = heightString.floatValue;
            return height;
        }
    } else {
        return 25;
    }
}

- (void)retrieveImages:(NSMutableArray *)imageLinksArray forCell:(ContentCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    int currentArrayIndex = 0;
    for (NSString *imageLink in imageLinksArray) {
        if ([imageLink isEqualToString:@""]) {
            NSLog(@"数组最后一项nil, 直接break");
            break;
        }
        NSLog(@"图片文件名:%@", imageLink);
        
        //先看看内存里有没有对应图片
        if ([_dicForImage objectForKey:imageLink] == nil) {
            NSLog(@"内存里没有对应图片, 开始查看本地");
            NSString *saveImageDataPath = [NSString new];
            if (currentArrayIndex == 0) {
                saveImageDataPath = [NSString stringWithFormat:@"%@/usr_portraitImages/%@", [[NSBundle mainBundle] bundlePath], imageLink];
            } else {
                saveImageDataPath = [NSString stringWithFormat:@"%@/usr_images/%@", [[NSBundle mainBundle] bundlePath], imageLink];
            }
            //没有的话，看看本地文件夹有没有对应图片，若有，存进内存图片数组，没有，联网拉取（说明上次保存数据库时候没有拉去图片成功）
            if ([_filemgr fileExistsAtPath: saveImageDataPath] == YES)
            {
                NSLog(@"本地文件夹有对应图片, 开始调入内存");
                NSData *dataFromFile = [NSData dataWithContentsOfFile:saveImageDataPath];
                UIImage *imageFromFile = [UIImage imageWithData:dataFromFile];
                [_dicForImage setValue:imageFromFile forKey:imageLink];
            } else {
                NSLog(@"******本地没有对应图片，开始从服务器拉取对应图片，并调入内存、写到本地");
                NSString *imageLinkWithServerPath = [NSString new];
                if (currentArrayIndex == 0) {
                    imageLinkWithServerPath = [NSString stringWithFormat:@"%@/usr_portraitImages/%@", serverUrl, imageLink];
                } else {
                    imageLinkWithServerPath = [NSString stringWithFormat:@"%@/usr_images/%@", serverUrl, imageLink];
                }
                NSURL *responseImageUrl = [NSURL URLWithString:[imageLinkWithServerPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                
                //通过注册到一个dic来判断特定图片到底有没有在另一进城进行下载
                if ([_dicForLoadingImage objectForKey:imageLink] == nil) {
                    dispatch_async(kBgQueue, ^{
                        [_dicForLoadingImage setObject:@"1" forKey:imageLink];
                        NSData *responseImageData = [NSData dataWithContentsOfURL:responseImageUrl];
                        UIImage *responseImage = [UIImage imageWithData:responseImageData];
                        [_dicForImage setValue:responseImage forKey:imageLink];
                        [responseImageData writeToFile:saveImageDataPath atomically:YES]; // 写文件，写的是nsdata
                        [_dicForLoadingImage removeObjectForKey:imageLink];
                        
                        NSLog(@"！！！准备回到main queue刷新ui！！！");
                        NSLog(@"图片名称%@", imageLink);
                        NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
                        [self performSelectorOnMainThread:@selector(reloadCellAtIndexPath:)
                                               withObject:indexPaths
                                            waitUntilDone:YES];
                        
                    });
                } else {
                    NSLog(@"已有相同进程正在运行, 不再重复创建!!!");
                }
            }
        } else {
            NSLog(@"太棒了，内存里有图片！");
        }
        currentArrayIndex ++;
    }
}

- (void)reloadCellAtIndexPath:(NSArray *)indexPaths {
    NSLog(@"！！！刷新有新图片的特定cell！！！");
    [self.contentTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

#pragma UICollectionView protocal

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    NSArray *imageArray = [_dicForImageLinksArray objectForKey:[NSString stringWithFormat:@"%d", collectionView.tag]];
    if (imageArray.count == 0 || imageArray.count == 1) {
        return 0;
    }
    return imageArray.count - 1;    //小心！！！始终大一的！！！
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionCell" forIndexPath:indexPath];
    UIImageView *tmpImageView = (UIImageView *)[cell viewWithTag:101];
    NSArray *imageArray = [_dicForImageLinksArray objectForKey:[NSString stringWithFormat:@"%d", collectionView.tag]];
    NSString *imageLink = [imageArray objectAtIndex:indexPath.row];
    UIImage *tmpImage = [_dicForImage objectForKey:imageLink];
    if (tmpImage != nil) {
        NSLog(@"collectionview内存里有照片");
        tmpImageView.image = tmpImage;
    } else {
        NSLog(@"collectionview内存里还没有照片");
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    currentPostID = collectionView.tag;
    currentImageIndex = indexPath.row;
    
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:101];
    UIImage *image = imageView.image;
    fullScreenImageView = [[[NSBundle mainBundle] loadNibNamed:@"FullScreenImageView" owner:nil options:nil] lastObject];
    
    //好似没有statusbar的20像素
    CGRect newFrame = CGRectMake(0, 0,[[UIScreen mainScreen] applicationFrame].size.width, [[UIScreen mainScreen] applicationFrame].size.height + 20);
    
    [fullScreenImageView setFrame:newFrame];
    fullScreenImageView.image = image;
    fullScreenImageView.contentMode = UIViewContentModeCenter;
    fullScreenImageView.contentMode = UIViewContentModeScaleAspectFit;
    fullScreenImageView.userInteractionEnabled = YES;
    
    objc_setAssociatedObject( fullScreenImageView,
                             "original_frame",
                             [NSValue valueWithCGRect: fullScreenImageView.frame],
                             OBJC_ASSOCIATION_RETAIN);
    
    [UIView transitionWithView: self.view.window
                      duration: 0.3
                       options: UIViewAnimationOptionAllowAnimatedContent
                    animations:^{
                        [self.view.window addSubview: fullScreenImageView];
                    } completion:^(BOOL finished) {
                        tgr = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector( onTap: )];
                        [fullScreenImageView addGestureRecognizer: tgr];
                        UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
                        [fullScreenImageView addGestureRecognizer:pgr];
                    }];
}

- (void)onTap:(UITapGestureRecognizer*)atgr {
    NSLog(@"user tapped...");
    [UIView animateWithDuration: 0.3
                     animations:^{
                         atgr.view.frame = [objc_getAssociatedObject( atgr.view, "original_frame" ) CGRectValue];
                     } completion:^(BOOL finished) {
                         [tgr.view removeFromSuperview];
                     }];
}

- (void)onPan:(UIPanGestureRecognizer*)pgr {
    CGPoint translation = [pgr translationInView:fullScreenImageView];
    CGPoint velocity = [pgr velocityInView:fullScreenImageView];
    //NSLog(@"%f", velocity.x);
    if(fabs(translation.y * 2) < fabs(translation.x))
    {
        NSLog(@"gesture went horizontal");
        if (velocity.x > 0) {
            NSLog(@"gesture went right");
            if (pgr.state == UIGestureRecognizerStateEnded) {
                NSLog(@"pan ended...");
                [self changeImageForFullScreenImageView:1];
            }
        }
        
        if(velocity.x < 0)
        {
            NSLog(@"gesture went left");
            if (pgr.state == UIGestureRecognizerStateEnded) {
                NSLog(@"pan ended...");
                [self changeImageForFullScreenImageView:0];
            }
        }
    }
}

- (void)changeImageForFullScreenImageView:(int)direction {
    //方向是不是往左边滑动
    if (direction == 0) {
        currentImageIndex ++;
        NSArray *imageArray = [_dicForImageLinksArray objectForKey:[NSString stringWithFormat:@"%d", currentPostID]];
        if (currentImageIndex < imageArray.count - 1) {
            NSString *imageLink = [imageArray objectAtIndex:currentImageIndex];
            UIImage *tmpImage = [_dicForImage objectForKey:imageLink];
            fullScreenImageView.image = tmpImage;
        } else {
            [self onTap:tgr];
        }
    } else {
        currentImageIndex --;
        NSArray *imageArray = [_dicForImageLinksArray objectForKey:[NSString stringWithFormat:@"%d", currentPostID]];
        if (currentImageIndex >= 0) {
            NSString *imageLink = [imageArray objectAtIndex:currentImageIndex];
            UIImage *tmpImage = [_dicForImage objectForKey:imageLink];
            fullScreenImageView.image = tmpImage;
        } else {
            [self onTap:tgr];
        }
    }
}

#pragma mark interact with server

- (IBAction)reload:(id)sender {
    //[_tencentOAuth authorize:_permissions];
    [self checkUpdate];
}

- (void)checkUpdate {
    [self getLocalMaxPostID];
    [self getLocalMaxCommentID];
    [self getRemoteMaxPostID];
    [self getRemoteMaxCommentID];
    
//    [self getLocalMaxCommentID];
//    [self getLocalMaxPostID];
//    [self getRemoteMaxCommentID];
//    [self getRemoteMaxPostID];
}

- (void)getRemoteMaxPostID {
    dispatch_async(kBgQueue, ^{
        NSString *checkUpdateUrlString = [NSString stringWithFormat:@"%@/api.php?api=1", serverUrl];
        NSURL *checkUpdateUrl = [NSURL URLWithString:[checkUpdateUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSError* error = nil;
        NSData* data = [NSData dataWithContentsOfURL:checkUpdateUrl
                                             options:NSDataReadingUncached
                                               error:&error];//居然能如此简单！！！
        if (error) {
            NSLog(@"getRemoteMaxPostID error:%@", error);
        } else
        {
            [self performSelectorOnMainThread:@selector(parseRemoteMaxPostID:)
                                   withObject:data
                                waitUntilDone:YES];
        }
    });
}

- (void)getRemoteMaxCommentID {
    dispatch_async(kBgQueue, ^{
        NSString *checkUpdateUrlString = [NSString stringWithFormat:@"%@/api.php?api=4", serverUrl];
        NSURL *checkUpdateUrl = [NSURL URLWithString:[checkUpdateUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSError* error = nil;
        NSData* data = [NSData dataWithContentsOfURL:checkUpdateUrl
                                             options:NSDataReadingUncached
                                               error:&error];//居然能如此简单！！！
        if (error) {
            NSLog(@"getRemoteMaxCommentID error:%@", error);
        } else
        {
            [self performSelectorOnMainThread:@selector(parseRemoteMaxCommentID:)
                                   withObject:data
                                waitUntilDone:YES];
        }
    });
}

- (void)parseRemoteMaxPostID:(NSData *)responseData {
    NSError* error;
    _postsArrayFromRemoteJson = [NSJSONSerialization
                             JSONObjectWithData:responseData //1
                             options:kNilOptions
                             error:&error];
    NSDictionary *tmpDic = [_postsArrayFromRemoteJson objectAtIndex:0];
    NSString *max = [tmpDic objectForKey:@"MAX(id)"];
    remoteMaxPostID = max.intValue;
    NSLog(@"remote最大postid是:%d", remoteMaxPostID);
    if (remoteMaxPostID > localMaxPostID) {
        existUpdate = true;
        [self retrievePostsUpdateFromServer];
        //[self readDataFromLocalDatabase];   //上面那个已经放到了另外一个进程，下面这个会直接运行，导致_postsArrayFromLocalDatabase是空
    } else {
        existUpdate = false;
        NSLog(@"本地数据库已是最新，不用更新");
        [self readPostsDataFromLocalDatabase];
    }
}

- (void)parseRemoteMaxCommentID:(NSData *)responseData {
    NSError* error;
    _commentsArrayFromRemoteJson = [NSJSONSerialization
                                 JSONObjectWithData:responseData //1
                                 options:kNilOptions
                                 error:&error];
    NSDictionary *tmpDic = [_commentsArrayFromRemoteJson objectAtIndex:0];
    NSString *max = [tmpDic objectForKey:@"MAX(id)"];
    remoteMaxCommentID = max.intValue;
    NSLog(@"remote最大commentid是:%d", remoteMaxCommentID);
    if (remoteMaxCommentID > localMaxCommentID) {
        existUpdate = true;
        [self retrieveCommentsUpdateFromServer];
    } else {
        existUpdate = false;
        NSLog(@"本地数据库已是最新，不用更新");
        [self readCommentsDataFromLocalDatabase];
    }
}

- (void)retrievePostsUpdateFromServer
{
    if (existUpdate) {
        NSLog(@"有更新，retrievePostsUpdateFromServer:开始拉取更新数据");
        dispatch_async(kBgQueue, ^{
            NSString *retrieveUpdateString = [NSString stringWithFormat:@"%@/api.php?api=2&low=%d&high=%d", serverUrl, (remoteMaxPostID - localMaxPostID) > 18 ? remoteMaxPostID - 18 + 1 : localMaxPostID + 1, remoteMaxPostID];
            NSURL *retrieveUpdateUrl = [NSURL URLWithString:[retrieveUpdateString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSError* error = nil;
            NSData* data = [NSData dataWithContentsOfURL:retrieveUpdateUrl
                                                 options:NSDataReadingUncached
                                                   error:&error];//居然能如此简单！！！
            if (error) {
                NSLog(@"retrievePostsUpdateFromServer error");
            } else
            {
                [self performSelectorOnMainThread:@selector(parsePostsUpdateData:)
                                       withObject:data
                                    waitUntilDone:YES];
                NSLog(@"拉取数据成功，大小共为%fKB", data.length/1024.0);
            }
        });
    }
}

- (void)retrieveCommentsUpdateFromServer
{
    if (existUpdate) {
        NSLog(@"有更新，retrieveCommentsUpdateFromServer:开始拉取更新数据");
        dispatch_async(kBgQueue, ^{
            NSString *retrieveUpdateString = [NSString stringWithFormat:@"%@/api.php?api=5&low=%d&high=%d", serverUrl, (remoteMaxCommentID - localMaxCommentID) > 38 ? remoteMaxCommentID - 38 + 1 : localMaxCommentID + 1, remoteMaxCommentID];
            NSURL *retrieveUpdateUrl = [NSURL URLWithString:[retrieveUpdateString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSError* error = nil;
            NSData* data = [NSData dataWithContentsOfURL:retrieveUpdateUrl
                                                 options:NSDataReadingUncached
                                                   error:&error];//居然能如此简单！！！
            if (error) {
                NSLog(@"retrieveCommentsUpdateFromServer error");
            } else
            {
                [self performSelectorOnMainThread:@selector(parseCommentsUpdateData:)
                                       withObject:data
                                    waitUntilDone:YES];
                NSLog(@"拉取数据成功，大小共为%fKB", data.length/1024.0);
            }
        });
    }
}

- (void)parsePostsUpdateData:(NSData *)responseData {
    NSString *someString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", someString);
    
    //parse out the json data, 一定要小心你接收到的json到底是什么格式的，dictionary还是array
    NSError* error;
    _postsArrayFromRemoteJson = [NSJSONSerialization
                        JSONObjectWithData:responseData //1
                        options:kNilOptions
                        error:&error];
    
    NSLog(@"共获得%d项数据", _postsArrayFromRemoteJson.count);
    for (NSDictionary *dicFromJson in _postsArrayFromRemoteJson) {
        //将每条post逐一写入本地数据库
        [self savePostsDataToDatabase:dicFromJson];
    }
    
    //小心，只能在这儿，等每一条都写完以后，才来read
    [self readPostsDataFromLocalDatabase];
}

- (void)parseCommentsUpdateData:(NSData *)responseData {
    NSString *someString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", someString);
    
    //parse out the json data, 一定要小心你接收到的json到底是什么格式的，dictionary还是array
    NSError* error;
    _commentsArrayFromRemoteJson = [NSJSONSerialization
                                 JSONObjectWithData:responseData //1
                                 options:kNilOptions
                                 error:&error];
    
    NSLog(@"共获得%d项数据", _commentsArrayFromRemoteJson.count);
    for (NSDictionary *dicFromJson in _commentsArrayFromRemoteJson) {
        //将每条post逐一写入本地数据库
        [self saveCommentsDataToDatabase:dicFromJson];
    }
    
    //小心，只能在这儿，等每一条都写完以后，才来read
    [self readCommentsDataFromLocalDatabase];
}

//评论相关部分
- (BOOL)sendComment:(NSString *)comment byIndex:(int)index {
    BOOL result = NO;
    //dispatch_async(kBgQueue, ^{
    
    int userID = accountViewController.userIDString.intValue;
    NSString *userName = accountViewController.name;
    if (userName == nil) {
        userName = @"未登录";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"！" message:@"您尚未登录"
                              
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return result;
    }
    
    NSDictionary *dicFromJson = [_postsArrayFromLocalDatabase objectAtIndex:index];
    NSString *postIDString = [dicFromJson objectForKey:@"postID"];
    int postID = postIDString.intValue;
    
    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *commentDate = [formatter stringFromDate:date];
    
    NSString *sendCommentString = [NSString stringWithFormat:@"%@/api.php?api=3&postID=%d&userID=%d&userName=%@&comment=%@&commentDate=%@", serverUrl, postID, userID, userName, comment, commentDate];
    NSURL *sendCommentUrl = [NSURL URLWithString:[sendCommentString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSError* error = nil;
    NSData* data = [NSData dataWithContentsOfURL:sendCommentUrl
                                         options:NSDataReadingUncached
                                           error:&error];//居然能如此简单！！！
    if (error) {
        NSLog(@"sendCommentUrl error");
    } else
    {
        NSLog(@"发送评论成功!");
        result = YES;
    }
    //});
    return result;
}

#pragma mark sqlite part

//数据库部分
- (void)createDatabase {
    NSLog(@"创建数据库文件");
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
    {
        //创建post内容的table
        char *errMsg;
        const char *sql_stmt1 =
        "CREATE TABLE IF NOT EXISTS posts (id INTEGER PRIMARY KEY AUTOINCREMENT, remotePostID INTEGER, type INTEGER, userID INTEGER, userName TEXT, content TEXT, videoLink TEXT, imageLinks TEXT, deviceName TEXT, systemNameAndVersion TEXT, onDisplay INTEGER, postDate TEXT)";
        
        if (sqlite3_exec(_database, sql_stmt1, NULL, NULL, &errMsg) == SQLITE_OK)
        {
            NSLog(@"成功创建table:posts");
        } else
        {
            NSLog(@"失败创建table:posts");
        }
        
        //创建评论的table
        const char *sql_stmt2 =
        "CREATE TABLE IF NOT EXISTS comments (id INTEGER PRIMARY KEY AUTOINCREMENT, remoteCommentID INTEGER, postID INTEGER, userID INTEGER, userName TEXT, comment TEXT, commentDate TEXT)";
        
        if (sqlite3_exec(_database, sql_stmt2, NULL, NULL, &errMsg) == SQLITE_OK)
        {
            NSLog(@"成功创建table:comments");
        } else
        {
            NSLog(@"失败创建table:comments");
        }
        sqlite3_close(_database);
    } else {
        NSLog(@"Failed to open/create database");
    }
}

- (IBAction)drop:(id)sender {
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK)   //库会自动创建新的数据库文件
    {
        //drop posts table
        char *errMsg;
        const char *sql_stmt1 = "DROP TABLE posts";
        if (sqlite3_exec(_database, sql_stmt1, NULL, NULL, &errMsg) == SQLITE_OK) {
            NSLog(@"Drop table posts");
            //sqlite3_close(_database);   //小心，关闭了就不能执行下一条了
        } else {
            NSLog(@"Unable to drop the table");
        }
        
        //drop comments table
        const char *sql_stmt2 = "DROP TABLE comments";
        if (sqlite3_exec(_database, sql_stmt2, NULL, NULL, &errMsg) == SQLITE_OK) {
            NSLog(@"Drop table comments");
            sqlite3_close(_database);
        } else {
            NSLog(@"Unable to drop the table");
        }
    } else {
        NSLog(@"Can not open the database");
    }
    
    //drop table之后马上创建table
    [self createDatabase];
}

- (void)getLocalMaxPostID {
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK)   //库会自动创建新的数据库文件
    {
        NSString *sqlQuery = @"SELECT MAX(remotePostID) FROM posts";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                localMaxPostID = sqlite3_column_int(statement, 0);
                NSLog(@"local最大postid是:%d", localMaxPostID);
            }
            sqlite3_finalize(statement);
            sqlite3_close(_database);
        } else {
            NSLog(@"读取数据库出错");
        }
    } else {
        NSLog(@"Can not open the database");
    }
}

- (void)getLocalMaxCommentID {
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK)   //库会自动创建新的数据库文件
    {
        NSString *sqlQuery = @"SELECT MAX(remoteCommentID) FROM comments";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                localMaxCommentID = sqlite3_column_int(statement, 0);
                NSLog(@"local最大commentid是:%d", localMaxCommentID);
            }
            sqlite3_finalize(statement);
            sqlite3_close(_database);
        } else {
            NSLog(@"读取数据库出错");
        }
    } else {
        NSLog(@"Can not open the database");
    }
}

- (void)savePostsDataToDatabase:(NSDictionary *)dicFromJson {
    NSLog(@"开始写入已存在数据库, 若有图片链接并联网拉取并保存本地");
    sqlite3_stmt *statement;
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
    {
        //变量虽然都是nsstring，但是在保存的时候还是转换成要求的类型
        NSString *remotePostID = [dicFromJson objectForKey:@"id"];
        NSString *type = [dicFromJson objectForKey:@"type"];
        NSString *userID = [dicFromJson objectForKey:@"userID"];
        NSString *userName = [dicFromJson objectForKey:@"userName"];
        NSString *content = [dicFromJson objectForKey:@"content"];
        NSString *videoLink = [dicFromJson objectForKey:@"videoLink"];
        NSString *imageLinks = [dicFromJson objectForKey:@"imageLinks"];
        NSString *deviceName = [dicFromJson objectForKey:@"deviceName"];
        NSString *systemNameAndVersion = [dicFromJson objectForKey:@"systemNameAndVersion"];
        NSString *onDisplay = [dicFromJson objectForKey:@"onDisplay"];
        NSString *postDate = [dicFromJson objectForKey:@"postDate"];
        
        NSString *insertSQL1 = [NSString stringWithFormat:
                                @"INSERT INTO posts (remotePostID, type, userID, userName, content, videoLink, imageLinks, deviceName, systemNameAndVersion, onDisplay, postDate) VALUES (\"%d\", \"%d\", \"%d\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%d\", \"%@\")", remotePostID.intValue, type.intValue, userID.intValue, userName, content, videoLink, imageLinks, deviceName, systemNameAndVersion, onDisplay.intValue, postDate];
        
        const char *insert_stmt1 = [insertSQL1 UTF8String];
        sqlite3_prepare_v2(_database, insert_stmt1, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"保存postID:%d数据至数据库成功", remotePostID.intValue);
        } else {
            NSLog(@"保存postID:%d数据至数据库失败", remotePostID.intValue);
        }
        sqlite3_finalize(statement);
        sqlite3_close(_database);
    } else {
        NSLog(@"Can not open the database");
    }
}

- (void)saveCommentsDataToDatabase:(NSDictionary *)dicFromJson {
    NSLog(@"开始将评论写入已存在数据库");
    sqlite3_stmt *statement;
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
    {
        //变量虽然都是nsstring，但是在保存的时候还是转换成要求的类型
        NSString *remoteCommentID = [dicFromJson objectForKey:@"id"];
        NSString *postID = [dicFromJson objectForKey:@"postID"];
        NSString *userID = [dicFromJson objectForKey:@"userID"];
        NSString *userName = [dicFromJson objectForKey:@"userName"];
        NSString *comment = [dicFromJson objectForKey:@"comment"];
        NSString *commentDate = [dicFromJson objectForKey:@"commentDate"];
        
        NSString *insertSQL1 = [NSString stringWithFormat:
                                @"INSERT INTO comments (remoteCommentID, postID, userID, userName, comment, commentDate) VALUES (\"%d\", \"%d\", \"%d\", \"%@\", \"%@\", \"%@\")", remoteCommentID.intValue, postID.intValue, userID.intValue, userName, comment, commentDate];
        
        const char *insert_stmt1 = [insertSQL1 UTF8String];
        sqlite3_prepare_v2(_database, insert_stmt1, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"保存CommentID:%d数据至数据库成功", remoteCommentID.intValue);
        } else {
            NSLog(@"保存CommentID:%d数据至数据库失败", remoteCommentID.intValue);
        }
        sqlite3_finalize(statement);
        sqlite3_close(_database);
    } else {
        NSLog(@"Can not open the database");
    }
}

- (void)readPostsDataFromLocalDatabase {
    NSLog(@"从本地数据库提取posts数据");
    //暂时直接重置_postsArrayFromLocalDatabase
    [_postsArrayFromLocalDatabase removeAllObjects];
    
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
    {
        NSString *sqlQuery = @"SELECT * FROM posts ORDER BY remotePostID DESC";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int postIDint = sqlite3_column_int(statement, 1);
                NSString *postID = [NSString stringWithFormat:@"%d", postIDint];
                int typeInt = sqlite3_column_int(statement, 2);
                NSString *type = [NSString stringWithFormat:@"%d", typeInt];
                int userIDInt = sqlite3_column_int(statement, 3);
                NSString *userID = [NSString stringWithFormat:@"%d", userIDInt];
                NSLog(@"userID:%@", userID);
                NSString *userName = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 4)];
                NSString *content = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 5)];
                NSString *imageLinks = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 7)];
                NSString *deviceName = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 8)];
                NSString *systemNameAndVersion = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 9)];
                NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:postID, @"postID", type, @"type", userID, @"userID", userName, @"userName", content, @"content", imageLinks, @"imageLinks", deviceName, @"deviceName", systemNameAndVersion, @"systemNameAndVersion", nil];
                [_postsArrayFromLocalDatabase addObject:dic];
            }
            sqlite3_finalize(statement);
            sqlite3_close(_database);
            
            //刷新table view
            NSLog(@"$$$$$$从本地读取%d条post完毕，开始刷新table view$$$$$$", _postsArrayFromLocalDatabase.count);
            heightNeedRecalculate = YES;
            [self.contentTableView reloadData];
            heightNeedRecalculate = NO;
        }
    } else {
        NSLog(@"Can not open the database");
    }
}

- (void)readCommentsDataFromLocalDatabase {
    NSLog(@"从本地数据库提取comments数据");
    //暂时直接重置_postsArrayFromLocalDatabase
    [_commentsDicFromLocalDatabase removeAllObjects];
    
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
    {
        NSString *sqlQuery = @"SELECT * FROM comments ORDER BY remoteCommentID DESC";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int commentIDint = sqlite3_column_int(statement, 1);
                NSString *commentID = [NSString stringWithFormat:@"%d", commentIDint];
                int postIDInt = sqlite3_column_int(statement, 2);
                NSString *postID = [NSString stringWithFormat:@"%d", postIDInt];
                int userIDInt = sqlite3_column_int(statement, 3);
                NSString *userID = [NSString stringWithFormat:@"%d", userIDInt];
                NSString *userName = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 4)];
                NSString *comment = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 5)];
                NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:commentID, @"commentID", postID, @"postID", userID, @"userID", userName, @"userName", comment, @"comment", nil];
                
                //将属于同一篇post的评论封装在一个array里面，最后在全部封装在一个dictionary里面，通过postID去索引
                if ([_commentsDicFromLocalDatabase objectForKey:postID] == nil) {
                    NSMutableArray *array = [NSMutableArray new];
                    [array addObject:dic];
                    [_commentsDicFromLocalDatabase setObject:array forKey:postID];
                } else {
                    NSMutableArray *array = [_commentsDicFromLocalDatabase objectForKey:postID];
                    [array addObject:dic];
                }
            }
            sqlite3_finalize(statement);
            sqlite3_close(_database);
            
            //刷新table view???
            NSLog(@"######从本地读取commens完毕#######");
            heightNeedRecalculate = YES;
            [self.contentTableView reloadData];
            heightNeedRecalculate = NO;
            
            
            
        }
    } else {
        NSLog(@"Can not open the database");
    }
}

#pragma mark UITextField Delegate Methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        //这里应该还要检查是否为空
        if ([self sendComment:textField.text byIndex:textField.tag]) {
            NSLog(@"发送评论成功, 重置textfield!");
            textField.text = @"";
            [textField endEditing:YES];
            [self checkUpdate];
        }
        [textField endEditing:YES];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField: textField up: YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField: textField up: NO];
}

- (void)animateTextField: (UITextField*) textField up: (BOOL) up
{
    //
}

@end
