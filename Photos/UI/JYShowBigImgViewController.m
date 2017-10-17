//
//  JYShowBigImgViewController.m
//  Photos
//
//  Created by JackYang on 2017/10/17.
//  Copyright © 2017年 JackYang. All rights reserved.
//

#import "JYShowBigImgViewController.h"
#import <Photos/Photos.h>
#import "JYBigImgCell.h"
#import "JYConst.h"
#import "JYAsset.h"
#import "PHPhotoLibrary+JYEXT.h"

@interface JYShowBigImgViewController ()<UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
{
    UICollectionView *_collectionView;
    
    UIButton *_navRightBtn;
    
    //底部view
    UIView   *_bottomView;
    UIButton *_btnOriginalPhoto;
    UIButton *_btnDone;
    //编辑按钮
    UIButton *_btnEdit;
    
    //双击的scrollView
    UIScrollView *_selectScrollView;
    NSInteger _currentPage;
    
//    NSArray *_arrSelPhotosBackup;
//    NSMutableArray *_arrSelAssets;
//    NSArray *_arrSelAssetsBackup;
    
    BOOL _isFirstAppear;
    
    BOOL _hideNavBar;
    
    //设备旋转前的index
    NSInteger _indexBeforeRotation;
    UICollectionViewFlowLayout *_layout;
    
    NSString *_modelIdentifile;
}

@end

@implementation JYShowBigImgViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //    NSLog(@"---- %s", __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _isFirstAppear = YES;
    _currentPage = self.selectIndex+1;
    _indexBeforeRotation = self.selectIndex;
    self.title = [NSString stringWithFormat:@"%ld/%ld", _currentPage, self.models.count];
    [self initNavBtns];
    [self initCollectionView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_isFirstAppear) {
        return;
    }
    [_collectionView setContentOffset:CGPointMake((kViewWidth+kItemMargin)*_indexBeforeRotation, 0)];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!_isFirstAppear) {
        return;
    }
    _isFirstAppear = NO;
    [self reloadCurrentCell];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _layout.minimumLineSpacing = kItemMargin;
    _layout.sectionInset = UIEdgeInsetsMake(0, kItemMargin/2, 0, kItemMargin/2);
    _layout.itemSize = self.view.bounds.size;
    [_collectionView setCollectionViewLayout:_layout];
    
    _collectionView.frame = CGRectMake(-kItemMargin/2, 0, kViewWidth+kItemMargin, kViewHeight);
    
    [_collectionView setContentOffset:CGPointMake((kViewWidth+kItemMargin)*_indexBeforeRotation, 0)];
    
    CGRect frame = _hideNavBar?CGRectMake(0, kViewHeight, kViewWidth, 44):CGRectMake(0, kViewHeight-44, kViewWidth, 44);
    _bottomView.frame = frame;
    _btnEdit.frame = CGRectMake(kViewWidth/2-30, 7, 60, 30);
    _btnDone.frame = CGRectMake(kViewWidth - 82, 7, 70, 30);
}

#pragma mark - 设备旋转
- (void)deviceOrientationChanged:(NSNotification *)notify
{
    //    NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
    _indexBeforeRotation = _currentPage - 1;
}

- (void)setModels:(NSArray<JYAsset *> *)models
{
    _models = models;
    //如果预览网络图片则返回
    if (models.firstObject.type == JYAssetTypeNetImage) {
        return;
    }
}

- (void)initNavBtns
{
    
}

#pragma mark - 初始化CollectionView
- (void)initCollectionView
{
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    [_collectionView registerClass:[JYBigImgCell class] forCellWithReuseIdentifier:@"JYBigImgCell"];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    [self.view addSubview:_collectionView];
}

- (void)initBottomView
{
    
}


- (void)handlerSingleTap
{
    _hideNavBar = !_hideNavBar;
    
    [self.navigationController setNavigationBarHidden:_hideNavBar animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:_hideNavBar withAnimation:UIStatusBarAnimationSlide];
    
    CGRect frame = _hideNavBar?CGRectMake(0, kViewHeight, kViewWidth, 44):CGRectMake(0, kViewHeight-44, kViewWidth, 44);
    [UIView animateWithDuration:0.3 animations:^{
        _bottomView.frame = frame;
    }];
}

#pragma mark - UICollectionDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.models.count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [((JYBigImgCell *)cell).previewView resetScale];
    ((JYBigImgCell *)cell).willDisplaying = YES;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [((JYBigImgCell *)cell).previewView handlerEndDisplaying];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JYBigImgCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JYBigImgCell" forIndexPath:indexPath];
    JYAsset *model = self.models[indexPath.row];
    
    
    cell.showGif = YES;
    cell.showLivePhoto = YES;
    cell.model = model;
    weakify(self);
    cell.singleTapCallBack = ^() {
        strongify(weakSelf);
        [strongSelf handlerSingleTap];
    };
    
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == (UIScrollView *)_collectionView) {
        JYAsset *m = [self getCurrentPageModel];
        if (!m || [_modelIdentifile isEqualToString:m.asset.localIdentifier]) return;
        _modelIdentifile = m.asset.localIdentifier;
        //改变导航标题
        self.title = [NSString stringWithFormat:@"%ld/%ld", _currentPage, self.models.count];
//        
//        _navRightBtn.selected = m.isSelected;
        
        if (m.type == JYAssetTypeGIF ||
            m.type == JYAssetTypeLivePhoto ||
            m.type == PHAssetMediaTypeVideo) {
            JYBigImgCell *cell = (JYBigImgCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentPage-1 inSection:0]];
            [cell pausePlay];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    [self reloadCurrentCell];
}

- (void)reloadCurrentCell
{
    JYAsset *m = [self getCurrentPageModel];
    if (m.type == JYAssetTypeGIF ||
        m.type == JYAssetTypeLivePhoto) {
        JYBigImgCell *cell = (JYBigImgCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentPage-1 inSection:0]];
        [cell reloadGifLivePhoto];
    }
}

- (JYAsset *)getCurrentPageModel
{
    CGPoint offset = _collectionView.contentOffset;
    
    CGFloat page = offset.x/(kViewWidth+kItemMargin);
    if (ceilf(page) >= self.models.count) {
        return nil;
    }
    NSString *str = [NSString stringWithFormat:@"%.0f", page];
    _currentPage = str.integerValue + 1;
    JYAsset *model = self.models[_currentPage-1];
    return model;
}

@end
