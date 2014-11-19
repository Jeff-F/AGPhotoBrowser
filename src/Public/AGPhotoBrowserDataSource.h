//
//  AGPhotoBrowserDataSource.h
//  AGPhotoBrowser
//
//  Created by Andrea Giavatto on 7/28/13.
//  Copyright (c) 2013 Andrea Giavatto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGPhotoBrowserCellProtocol.h"

@class AGPhotoBrowser;

@protocol AGPhotoBrowserDataSource <NSObject>

- (NSInteger)numberOfPhotosForPhotoBrowser:(AGPhotoBrowser *)photoBrowser;

@optional
- (Class)cellClassForPhotoBrowser:(AGPhotoBrowser *)browser;
- (UIImage *)photoBrowser:(AGPhotoBrowser *)photoBrowser imageAtIndex:(NSInteger)index;;
- (NSString *)photoBrowser:(AGPhotoBrowser *)photoBrowser URLStringForImageAtIndex:(NSInteger)index;
- (NSString *)photoBrowser:(AGPhotoBrowser *)photoBrowser titleForImageAtIndex:(NSInteger)index;
- (NSString *)photoBrowser:(AGPhotoBrowser *)photoBrowser descriptionForImageAtIndex:(NSInteger)index;
- (BOOL)photoBrowser:(AGPhotoBrowser *)photoBrowser willDisplayActionButtonAtIndex:(NSInteger)index;
- (BOOL)photoBrowser:(AGPhotoBrowser *)photoBrowser shouldDisplayOverlayViewAtIndex:(NSInteger)index;

@end
