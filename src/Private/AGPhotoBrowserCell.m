//
//  AGPhotoBrowserCell.m
//  AGPhotoBrowser
//
//  Created by Andrea Giavatto on 1/5/14.
//  Copyright (c) 2014 Andrea Giavatto. All rights reserved.
//

#import "AGPhotoBrowserCell.h"
#import "AGPhotoBrowserZoomableView.h"

@interface AGPhotoBrowserCell () <AGPhotoBrowserZoomableViewDelegate>

@property (nonatomic, strong) AGPhotoBrowserZoomableView *zoomableView;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign, getter = isZoomedIn) BOOL zoomedIn;

@end

@implementation AGPhotoBrowserCell

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self p_setupCell];
	}
	
	return self;
}

- (void)p_setupCell
{
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.contentView addSubview:self.zoomableView];
}

- (void)prepareForReuse
{
	[super prepareForReuse];
}

+ (BOOL)requiresConstraintBasedLayout
{
	return YES;
}

- (void)updateConstraints
{
	[self.contentView removeConstraints:self.contentView.constraints];
	
	NSDictionary *constrainedViews = NSDictionaryOfVariableBindings(_zoomableView);
	
	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_zoomableView]|"
																			 options:0
																			 metrics:@{}
																			   views:constrainedViews]];
	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_zoomableView]|"
																			 options:0
																			 metrics:@{}
																			   views:constrainedViews]];
	
	[super updateConstraints];
}


#pragma mark - Getters

- (AGPhotoBrowserZoomableView *)zoomableView
{
	if (!_zoomableView) {
		_zoomableView = [[AGPhotoBrowserZoomableView alloc] initWithFrame:CGRectZero];
		_zoomableView.translatesAutoresizingMaskIntoConstraints = NO;
		_zoomableView.userInteractionEnabled = YES;
        _zoomableView.zoomableDelegate = self;
		
		[_zoomableView addGestureRecognizer:self.panGesture];
//		[_zoomableView AG_rotateRadians:M_PI_2];
	}
	
	return _zoomableView;
}

- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(p_imageViewPanned:)];
		_panGesture.delegate = self;
		_panGesture.maximumNumberOfTouches = 1;
		_panGesture.minimumNumberOfTouches = 1;
    }
    
    return _panGesture;
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.panGesture) {
        UIView *imageView = [gestureRecognizer view];
        CGPoint translation = [gestureRecognizer translationInView:[imageView superview]];

        // -- Check for movement axis
        if (fabsf(translation.x) > fabsf(translation.y) && !self.zoomedIn) {
            return YES;
        }
    }
	
    return NO;
}


#pragma mark - Setters

- (void)setCellImage:(UIImage *)cellImage
{
	[self.zoomableView setImage:cellImage];
	
	[self setNeedsUpdateConstraints];
}


#pragma mark - Public methods

- (void)resetZoomScale
{
	[self.zoomableView setZoomScale:1.];
}


#pragma mark - Private methods

- (void)p_imageViewPanned:(UIPanGestureRecognizer *)recognizer
{
	[self.delegate didPanOnZoomableViewForCell:self withRecognizer:recognizer];
}


#pragma mark - AGPhotoBrowserZoomableViewDelegate

- (void)didDoubleTapZoomableView:(AGPhotoBrowserZoomableView *)zoomableView
{
	[self.delegate didDoubleTapOnZoomableViewForCell:self];
}

- (void)didZoomInZoomableView:(AGPhotoBrowserZoomableView *)zoomableView
{
	self.zoomedIn = YES;
}

- (void)didZoomOutZoomableView:(AGPhotoBrowserZoomableView *)zoomableView
{
	self.zoomedIn = NO;
}

@end
