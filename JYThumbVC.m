//
//  JYThumbVC.m
//  Photos
//
//  Created by JackYang on 2017/9/25.
//  Copyright © 2017年 JackYang. All rights reserved.
//

#import "JYThumbVC.h"
#import "PHPhotoLibrary+JYEXT.h"
#import <Photos/Photos.h>
#import "JYConst.h"
#import "JYProgressHUD.h"
#import "JYAsset.h"
#import "JYCollectionViewCell.h"
#import "JYForceTouchPreviewController.h"
#import "JYShowBigImgViewController.h"

@interface JYThumbVC ()<UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) NSMutableArray<JYAsset *> *arrDataSources;

@end

@implementation JYThumbVC

- (void)dealloc
{
    //    NSLog(@"---- %s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (JYAssetList *)albumListModel
{
    if (!_albumListModel) {
        _albumListModel = [PHPhotoLibrary getCameraRollAlbumList:YES allowSelectImage:YES];
    }
    return _albumListModel;
}

- (NSMutableArray<JYAsset *> *)arrDataSources
{
    if (!_arrDataSources) {
        JYProgressHUD *hud = [[JYProgressHUD alloc] init];
        [hud show];
        _arrDataSources = [NSMutableArray arrayWithArray:self.albumListModel.models];
        [hud hide];
    }
    return _arrDataSources;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.albumListModel.title;
    

    [self initNavBtn];
    [self initCollectionView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

-(void)deviceOrientationChanged:(UIDeviceOrientation)ori
{
    
}

- (void)initCollectionView
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    CGFloat width = .0;
    if (orientation == UIDeviceOrientationLandscapeLeft ||
        orientation == UIDeviceOrientationLandscapeRight) {
        width = kViewHeight;
    } else {
        width = kViewWidth;
    }
    
    NSInteger columnCount;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        columnCount = 6;
    } else {
        columnCount = 4;
    }
    
    layout.itemSize = CGSizeMake((width-1.5*columnCount)/columnCount, (width-1.5*columnCount)/columnCount);
    layout.minimumInteritemSpacing = 1.5;
    layout.minimumLineSpacing = 1.5;
    layout.sectionInset = UIEdgeInsetsMake(3, 0, 3, 0);
    
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self.collectionView registerClass:NSClassFromString(@"JYCollectionViewCell") forCellWithReuseIdentifier:@"JYCollectionViewCell"];
    //注册3d touch
    if ([self forceTouchAvailable])
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    [self.collectionView reloadData];
}

- (BOOL)forceTouchAvailable
{
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
        return self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    } else {
        return NO;
    }
}

- (void)initNavBtn
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat width = 40; //
    btn.frame = CGRectMake(0, 0, width, 44);
    btn.titleLabel.font = [UIFont systemFontOfSize:16];
    [btn setTitle:@"取消" forState:UIControlStateNormal];
    [btn setTitleColor:kNavBar_tintColor forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
}

- (UIViewController *)getBigImageVCWithData:(NSArray<JYAsset *> *)data index:(NSInteger)index
{
    JYShowBigImgViewController *vc = [[JYShowBigImgViewController alloc] init];
    vc.models = data.copy;
    vc.selectIndex = index;
//    weakify(self);
    [vc setBtnBackBlock:^(NSArray<JYAsset *> *selectedModels, BOOL isOriginal) {
//        strongify(weakSelf);
//        [strongSelf.collectionView reloadData];
    }];
    return vc;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.arrDataSources.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    JYCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JYCollectionViewCell" forIndexPath:indexPath];
    
    JYAsset *model;
    model = self.arrDataSources[indexPath.row];
    
//    weakify(self);
//    __weak typeof(cell) weakCell = cell;
    
    cell.selectedBlock = ^(BOOL selected) {
//        strongify(weakSelf);
//        __strong typeof(weakCell) strongCell = weakCell;
        
    };
    
    cell.allSelectGif = YES;
    cell.allSelectLivePhoto = YES;
    cell.showSelectBtn = NO;
    cell.cornerRadio = 0;
    cell.showMask = NO;
    cell.maskColor = [UIColor blackColor];
    cell.model = model;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSInteger index = indexPath.row;
    JYAsset *model = self.arrDataSources[index];
    
    
    UIViewController *vc = [self getMatchVCWithModel:model];
    if (vc) {
        [self showViewController:vc sender:nil];
    }
}

- (UIViewController *)getMatchVCWithModel:(JYAsset *)model
{
    
    NSArray *arr = [PHPhotoLibrary getPhotoInResult:self.albumListModel.result allowSelectVideo:YES allowSelectImage:YES allowSelectGif:YES allowSelectLivePhoto:YES];
    int i = 0;
    for (JYAsset *m in arr) {
        if ([m.asset.localIdentifier isEqualToString:model.asset.localIdentifier])
            break;
        i++;
    }
    return [self getBigImageVCWithData:arr index:i];
}
#pragma mark - UIViewControllerPreviewingDelegate
//!!!!: 3D Touch
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    
    if (!indexPath) {
        return nil;
    }
    
//    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
#warning
    // 判断cell是否不可3dtouch
    
    //设置突出区域
    previewingContext.sourceRect = [self.collectionView cellForItemAtIndexPath:indexPath].frame;
    
    JYForceTouchPreviewController *vc = [[JYForceTouchPreviewController alloc] init];
    
    NSInteger index = indexPath.row;
    JYAsset *model = self.arrDataSources[index];
    vc.model = model;
    vc.allowSelectGif = YES;
    vc.allowSelectLivePhoto = YES;
    vc.preferredContentSize = [self getSize:model];
    
    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    JYAsset *model = [(JYForceTouchPreviewController *)viewControllerToCommit model];
    
    UIViewController *vc = [self getMatchVCWithModel:model];
    if (vc) {
        [self showViewController:vc sender:self];
    }
}

- (CGSize)getSize:(JYAsset *)model
{
    CGFloat w = MIN(model.asset.pixelWidth, kViewWidth);
    CGFloat h = w * model.asset.pixelHeight / model.asset.pixelWidth;
    if (isnan(h)) return CGSizeZero;
    
    if (h > kViewHeight || isnan(h)) {
        h = kViewHeight;
        w = h * model.asset.pixelWidth / model.asset.pixelHeight;
    }
    
    return CGSizeMake(w, h);
}


@end
