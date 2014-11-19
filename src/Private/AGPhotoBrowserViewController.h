//
//  AGPhotoBrowserViewController.h
//  AGPhotoBrowser
//
//  Created by Andrea Giavatto on 8/23/14.
//  Copyright (c) 2014 Andrea Giavatto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AGPhotoBrowserDataSource.h"
#import "AGPhotoBrowserDelegate.h"

@interface AGPhotoBrowserViewController : UIViewController

@property (nonatomic, weak) id<AGPhotoBrowserDelegate> delegate;
@property (nonatomic, weak) id<AGPhotoBrowserDataSource> dataSource;

- (instancetype)initWithPhotoBrowser:(AGPhotoBrowser *)photoBrowser;

@end
