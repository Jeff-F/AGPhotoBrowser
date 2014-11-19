//
//  AGPhotoBrowserView.h
//  AGPhotoBrowser
//
//  Created by Andrea Giavatto on 7/28/13.
//  Copyright (c) 2013 Andrea Giavatto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AGPhotoBrowserCell.h"
#import "AGPhotoBrowserDelegate.h"
#import "AGPhotoBrowserDataSource.h"

#define AGPhotoBrowserVersion @"2.0"

@interface AGPhotoBrowser : NSObject

@property (nonatomic, weak) id<AGPhotoBrowserDelegate> delegate;
@property (nonatomic, weak) id<AGPhotoBrowserDataSource> dataSource;

@property (nonatomic, strong, readonly) UIButton *doneButton __deprecated;

/**
 *  Replaced by showAnimated:
 *  See its description for more information.
 */
- (void)show __deprecated;

/**
 *  Shows the photo browser with an optional fade-in animation.
 *  The photo browser uses a new separate window with level UIWindowLevelStatusBar
 *  in order to be visible on top of everything to create a real fullscreen experience
 *  both on iOS6 and iOS7.
 *
 *  @param animated YES to animate the transition with a fade-in effect, NO to make the transition immediate.
 *  @param completionBlock a completion block to be called when the animation is completed.
 */
- (void)showAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completionBlock;

/**
 *  Replaced by showFromIndex:animated:
 *  See its description for more information.
 */
- (void)showFromIndex:(NSInteger)initialIndex __deprecated;

/**
 *  Shows the photo browser from a specific initial index with an optional fade-in
 *  animation.
 *  The photo browser uses a new separate window with level UIWindowLevelStatusBar
 *  in order to be visible on top of everything to create a real fullscreen experience
 *  both on iOS6 and iOS7.
 *
 *  @param initialIndex the index must be in the range (0, numberOfPhotosForPhotoBrowser:)
 *  @param animated     YES to animate the transition with a fade-in effect, NO to make the transition immediate.
 *  @param completionBlock a completion block to be called when the animation is completed.
 */
- (void)showFromIndex:(NSInteger)initialIndex animated:(BOOL)animated completion:(void(^)(BOOL finished))completionBlock;

/**
 *  Replaced by hideAnimated:withCompletion
 *  See its description for more information.
 */
- (void)hideWithCompletion:(void(^)(BOOL finished))completionBlock __deprecated;

/**
 *  Hides the photo browser with an optional fade-out animation. The completion block is called
 *  when the animation has completed.
 *
 *  @param animated        YES to animate the transition with a fade-out effect, NO to make the transition immediate.
 *  @param completionBlock a completion block to be called when the animation is completed.
 */
- (void)hideAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completionBlock;

@end
