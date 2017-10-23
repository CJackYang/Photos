//
//  JYThumbVC.h
//  Photos
//
//  Created by JackYang on 2017/9/25.
//  Copyright © 2017年 JackYang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMPZoomTransitionAnimator.h"

@class JYAssetList;

@interface JYThumbVC : UIViewController<RMPZoomTransitionAnimating>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//相册model
@property (nonatomic, strong) JYAssetList *albumListModel;

@end
