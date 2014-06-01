//
//  AGPhotoBrowserView.m
//  AGPhotoBrowser
//
//  Created by Andrea Giavatto on 7/28/13.
//  Copyright (c) 2013 Andrea Giavatto. All rights reserved.
//

#import "AGPhotoBrowserView.h"

#import <QuartzCore/QuartzCore.h>
#import "AGPhotoBrowserOverlayView.h"
#import "AGPhotoBrowserZoomableView.h"
#import "AGPhotoBrowserCell.h"
#import "AGPhotoBrowserCellProtocol.h"
#import "UIView+Rotate.h"


@interface AGPhotoBrowserView () <
	AGPhotoBrowserOverlayViewDelegate,
	AGPhotoBrowserCellDelegate,
	UITableViewDataSource,
	UITableViewDelegate
>
{
	CGPoint _startingPanPoint;
	NSInteger _currentlySelectedIndex;
}

//@property (nonatomic, strong, readwrite) UIButton *doneButton;
@property (nonatomic, strong) UITableView *photoTableView;
@property (nonatomic, strong) AGPhotoBrowserOverlayView *overlayView;

@property (nonatomic, strong) UIWindow *previousWindow;
@property (nonatomic, strong) UIWindow *currentWindow;

@property (atomic, assign) BOOL changingOrientation;
@property (nonatomic, assign, readonly) CGFloat cellHeight;
@property (nonatomic, assign, getter = isDisplayingDetailedView) BOOL displayingDetailedView;

@end


@implementation AGPhotoBrowserView

NSString * const cellIdentifier = @"AGPhotoBrowserCell";
NSInteger const AGPhotoBrowserThresholdToCenter = 150;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        // Initialization code
		[self setupView];
    }
    return self;
}

- (void)setupView
{
	self.userInteractionEnabled = NO;
	self.backgroundColor = [UIColor colorWithWhite:0. alpha:0.];
	_currentlySelectedIndex = NSNotFound;
	
	[self addSubview:self.photoTableView];
//	[self addSubview:self.doneButton];
	[self addSubview:self.overlayView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarDidChangeFrame:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)updateConstraints
{
	[self removeConstraints:self.constraints];
	
	NSDictionary *constrainedViews = NSDictionaryOfVariableBindings(_photoTableView, _overlayView);
	NSDictionary *metrics = @{};
	// -- Horizontal constraints
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_photoTableView]|" options:0 metrics:metrics views:constrainedViews]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_overlayView]|" options:0	 metrics:metrics views:constrainedViews]];
	// -- Vertical constraints
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_photoTableView]|" options:0 metrics:metrics views:constrainedViews]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_overlayView]|" options:0	 metrics:metrics views:constrainedViews]];
	
	[super updateConstraints];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}


#pragma mark - Getters

//- (UIButton *)doneButton
//{
//	if (!_doneButton) {
//		_doneButton = [[UIButton alloc] initWithFrame:CGRectZero];
//		_doneButton.translatesAutoresizingMaskIntoConstraints = NO;
//		[_doneButton setTitle:NSLocalizedString(@"Done", @"Title for Done button") forState:UIControlStateNormal];
//		_doneButton.layer.cornerRadius = 3.0f;
//		_doneButton.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.9].CGColor;
//		_doneButton.layer.borderWidth = 1.0f;
//		[_doneButton setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:0.5]];
//		[_doneButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateNormal];
//		[_doneButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateHighlighted];
//		[_doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
//		_doneButton.alpha = 0.;
//		
//		[_doneButton addTarget:self action:@selector(p_doneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//	}
//	
//	return _doneButton;
//}

- (UITableView *)photoTableView
{
	if (!_photoTableView) {
		_photoTableView = [[UITableView alloc] initWithFrame:CGRectZero];
		_photoTableView.translatesAutoresizingMaskIntoConstraints = NO;
		_photoTableView.dataSource = self;
		_photoTableView.delegate = self;
		_photoTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		_photoTableView.backgroundColor = [UIColor clearColor];
		_photoTableView.pagingEnabled = YES;
		_photoTableView.showsVerticalScrollIndicator = NO;
		_photoTableView.showsHorizontalScrollIndicator = NO;
		_photoTableView.alpha = 0.;
	}
	
	return _photoTableView;
}

- (AGPhotoBrowserOverlayView *)overlayView
{
	if (!_overlayView) {
		_overlayView = [[AGPhotoBrowserOverlayView alloc] initWithFrame:CGRectZero];
		_overlayView.translatesAutoresizingMaskIntoConstraints = NO;
        _overlayView.delegate = self;
		[_overlayView AG_rotateRadians:M_PI_2];
	}
	
	return _overlayView;
}

- (CGFloat)cellHeight
{
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	if (UIDeviceOrientationIsLandscape(orientation)) {
		return CGRectGetHeight(self.currentWindow.frame);
	}
	
	return CGRectGetWidth(self.currentWindow.frame);
}


#pragma mark - Setters

- (void)setDisplayingDetailedView:(BOOL)displayingDetailedView
{
	_displayingDetailedView = displayingDetailedView;
	
	[self.overlayView setOverlayVisible:_displayingDetailedView animated:YES];
	
//	[UIView animateWithDuration:AGPhotoBrowserAnimationDuration
//					 animations:^(){
//						 self.doneButton.alpha = newAlpha;
//					 }];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.cellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger number = [self.dataSource numberOfPhotosForPhotoBrowser:self];
    
    if (number > 0 && _currentlySelectedIndex == NSNotFound && !self.currentWindow.hidden) {
        // initialize with info for the first photo in photoTable
        [self setupPhotoForIndex:0];
    }
    
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell<AGPhotoBrowserCellProtocol> *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        if ([self.dataSource respondsToSelector:@selector(cellForBrowser:withReuseIdentifier:)]) {
            cell = [self.dataSource cellForBrowser:self withReuseIdentifier:cellIdentifier];
        } else {
            // -- Provide fallback if the user does not want its own implementation of a cell
            cell = [[AGPhotoBrowserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.delegate = self;
    }

    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell<AGPhotoBrowserCellProtocol> *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.dataSource respondsToSelector:@selector(photoBrowser:shouldDisplayOverlayViewAtIndex:)]) {
		BOOL overlayIsVisible = [_dataSource photoBrowser:self shouldDisplayOverlayViewAtIndex:indexPath.row];
//		self.overlayView.hidden = !overlayIsVisible;
	}
	
    if ([cell respondsToSelector:@selector(resetZoomScale)]) {
        [cell resetZoomScale];
    }
    
    if ([self.dataSource respondsToSelector:@selector(photoBrowser:URLStringForImageAtIndex:)] && [cell respondsToSelector:@selector(setCellImageWithURL:)]) {
        [cell setCellImageWithURL:[NSURL URLWithString:[_dataSource photoBrowser:self URLStringForImageAtIndex:indexPath.row]]];
    } else if ([_dataSource respondsToSelector:@selector(photoBrowser:imageAtIndex:)]) {
        [cell setCellImage:[_dataSource photoBrowser:self imageAtIndex:indexPath.row]];
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.displayingDetailedView = !self.isDisplayingDetailedView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	cell.backgroundColor = [UIColor clearColor];
}


#pragma mark - AGPhotoBrowserCellDelegate

- (void)didPanOnZoomableViewForCell:(id<AGPhotoBrowserCellProtocol>)cell withRecognizer:(UIPanGestureRecognizer *)recognizer
{
	[self p_imageViewPanned:recognizer];
}

- (void)didDoubleTapOnZoomableViewForCell:(id<AGPhotoBrowserCellProtocol>)cell
{
	self.displayingDetailedView = !self.isDisplayingDetailedView;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.currentWindow.hidden && !self.changingOrientation) {        
        CGPoint targetContentOffset = scrollView.contentOffset;
        
        UITableView *tv = (UITableView*)scrollView;
        NSIndexPath *indexPathOfTopRowAfterScrolling = [tv indexPathForRowAtPoint:targetContentOffset];

        [self setupPhotoForIndex:indexPathOfTopRowAfterScrolling.row];
    }
}

- (void)setupPhotoForIndex:(int)index
{
    _currentlySelectedIndex = index;
	    
    if ([self.dataSource respondsToSelector:@selector(photoBrowser:willDisplayActionButtonAtIndex:)]) {
//        self.overlayView.actionButton.hidden = ![self.dataSource photoBrowser:self willDisplayActionButtonAtIndex:_currentlySelectedIndex];
    } else {
//        self.overlayView.actionButton.hidden = NO;
    }
    
	if ([self.dataSource respondsToSelector:@selector(photoBrowser:titleForImageAtIndex:)]) {
		self.overlayView.title = [self.dataSource photoBrowser:self titleForImageAtIndex:_currentlySelectedIndex];
	} else {
        self.overlayView.title = @"";
    }
	
	if ([self.dataSource respondsToSelector:@selector(photoBrowser:descriptionForImageAtIndex:)]) {
		self.overlayView.description = [self.dataSource photoBrowser:self descriptionForImageAtIndex:_currentlySelectedIndex];
	} else {
        self.overlayView.description = @"";
    }
}


#pragma mark - Public methods

- (void)show
{
    NSLog(@"This method has been deprecated and will be removed in a future release. Use showAnimated: instead.");
	return;
}

- (void)showAnimated:(BOOL)animated withCompletion:(void (^)(BOOL))completionBlock
{
	self.previousWindow = [[UIApplication sharedApplication] keyWindow];
    
    self.currentWindow = [[UIWindow alloc] initWithFrame:self.previousWindow.bounds];
    self.currentWindow.windowLevel = UIWindowLevelStatusBar;
    self.currentWindow.hidden = NO;
    self.currentWindow.backgroundColor = [UIColor clearColor];
    [self.currentWindow makeKeyAndVisible];
    [self.currentWindow addSubview:self];
	
	NSTimeInterval animationDuration = AGPhotoBrowserAnimationDuration;
	if (!animated) {
		animationDuration = 0.f;
	}
	
	[UIView animateWithDuration:animationDuration
					 animations:^(){
						 self.backgroundColor = [UIColor colorWithWhite:0. alpha:1.];
					 }
					 completion:^(BOOL finished){
						 self.userInteractionEnabled = YES;
						 self.displayingDetailedView = YES;
						 self.photoTableView.alpha = 1.;
						 [self.photoTableView reloadData];
						 
						 if (completionBlock) {
							 completionBlock(finished);
						 }
					 }];
}

- (void)showFromIndex:(NSInteger)initialIndex
{
	NSLog(@"This method has been deprecated and will be removed in a future release. Use showFromIndex:animated: instead.");
	return;
}

- (void)showFromIndex:(NSInteger)initialIndex animated:(BOOL)animated withCompletion:(void (^)(BOOL))completionBlock
{
	[self showAnimated:animated
		withCompletion:^(BOOL finished) {
			if (initialIndex < [self.dataSource numberOfPhotosForPhotoBrowser:self]) {
				[self.photoTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:initialIndex inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			}
			if (completionBlock) {
				completionBlock(finished);
			}
		}];
}

- (void)hideWithCompletion:(void(^)(BOOL finished))completionBlock
{
	NSLog(@"This method has been deprecated and will be removed in a future release. Use hideAnimated:withCompletion: instead.");
	return;
}

- (void)hideAnimated:(BOOL)animated withCompletion:(void (^)(BOOL))completionBlock
{
	NSTimeInterval animationDuration = AGPhotoBrowserAnimationDuration;
	if (!animated) {
		animationDuration = 0.f;
	}
	[UIView animateWithDuration:animationDuration
					 animations:^(){
						 self.photoTableView.alpha = 0.;
						 self.backgroundColor = [UIColor colorWithWhite:0. alpha:0.];
					 }
					 completion:^(BOOL finished){
						 self.userInteractionEnabled = NO;
                         [self removeFromSuperview];
                         [self.previousWindow makeKeyAndVisible];
                         self.currentWindow.hidden = YES;
                         self.currentWindow = nil;
						 
						 if(completionBlock) {
							 completionBlock(finished);
						 }
					 }];
}


#pragma mark - AGPhotoBrowserOverlayViewDelegate

- (void)sharingView:(AGPhotoBrowserOverlayView *)sharingView didTapOnActionButton:(UIButton *)actionButton
{
	if ([self.delegate respondsToSelector:@selector(photoBrowser:didTapOnActionButton:atIndex:)]) {
		[self.delegate photoBrowser:self didTapOnActionButton:actionButton atIndex:_currentlySelectedIndex];
	}
}


#pragma mark - Recognizers

- (void)p_imageViewPanned:(UIPanGestureRecognizer *)recognizer
{
	AGPhotoBrowserZoomableView *imageView = (AGPhotoBrowserZoomableView *)recognizer.view;
	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		// -- Disable table view scrolling
		self.photoTableView.scrollEnabled = NO;
		// -- Hide detailed view
		self.displayingDetailedView = NO;
		_startingPanPoint = imageView.center;
		return;
	}
	
	if (recognizer.state == UIGestureRecognizerStateEnded) {
		// -- Enable table view scrolling
		self.photoTableView.scrollEnabled = YES;
		// -- Check if user dismissed the view
		CGPoint endingPanPoint = [recognizer translationInView:self];
		CGPoint translatedPoint = CGPointMake(_startingPanPoint.x + endingPanPoint.x, _startingPanPoint.y);
		
		imageView.center = translatedPoint;
		int heightDifference = abs(floor(_startingPanPoint.x - translatedPoint.x));
		
		if (heightDifference <= AGPhotoBrowserThresholdToCenter) {
			// -- Back to original center
			[UIView animateWithDuration:AGPhotoBrowserAnimationDuration
							 animations:^(){
								 self.backgroundColor = [UIColor colorWithWhite:0. alpha:1.];
								 imageView.center = self->_startingPanPoint;
							 } completion:^(BOOL finished){
								 // -- show detailed view?
								 self.displayingDetailedView = YES;
							 }];
		} else {
			// -- Animate out!
			typeof(self) weakSelf __weak = self;
			[self hideAnimated:YES withCompletion:^(BOOL finished){
				typeof(weakSelf) strongSelf __strong = weakSelf;
				if (strongSelf) {
					imageView.center = strongSelf->_startingPanPoint;
				}
			}];
		}
	} else {
		CGPoint middlePanPoint = [recognizer translationInView:self];
		CGPoint translatedPoint = CGPointMake(_startingPanPoint.x + middlePanPoint.x, _startingPanPoint.y);
		
		imageView.center = translatedPoint;
		int heightDifference = abs(floor(_startingPanPoint.x - translatedPoint.x));
		CGFloat ratio = (_startingPanPoint.x - heightDifference)/_startingPanPoint.x;
		self.backgroundColor = [UIColor colorWithWhite:0. alpha:ratio];
	}
}


#pragma mark - Private methods

//- (void)p_doneButtonTapped:(UIButton *)sender
//{
//	if ([self.delegate respondsToSelector:@selector(photoBrowser:didTapOnDoneButton:)]) {
//		self.displayingDetailedView = NO;
//		[self.delegate photoBrowser:self didTapOnDoneButton:sender];
//	}
//}


#pragma mark - Orientation change

- (void)statusBarDidChangeFrame:(NSNotification *)notification
{
	self.changingOrientation = YES;
	
    // -- Get the device orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	CGFloat angleTable = UIInterfaceOrientationAngleOfOrientation(orientation);
	CGAffineTransform viewTransform = CGAffineTransformMakeRotation(angleTable);
	CGRect viewFrame = [UIScreen mainScreen].bounds;
	
	// -- Update table
	[self setTransform:viewTransform andFrame:viewFrame forView:self];
	[self setNeedsUpdateConstraints];
	
	[self.photoTableView reloadData];
	[self.photoTableView layoutIfNeeded];
	[self.photoTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_currentlySelectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
	
	self.changingOrientation = NO;
}

- (void)setTransform:(CGAffineTransform)transform andFrame:(CGRect)frame forView:(UIView *)view
{
	if (!CGAffineTransformEqualToTransform(view.transform, transform)) {
        view.transform = transform;
    }
    if (!CGRectEqualToRect(view.frame, frame)) {
        view.frame = frame;
    }
}

CGFloat UIInterfaceOrientationAngleOfOrientation(UIDeviceOrientation orientation)
{
    CGFloat angle;
    
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            angle = 0;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = M_PI;
            break;
        default:
            angle = -M_PI_2;
            break;
    }
    
    return angle;
}

@end
