//
//  AGPhotoBrowserViewController.m
//  AGPhotoBrowser
//
//  Created by Andrea Giavatto on 8/23/14.
//  Copyright (c) 2014 Andrea Giavatto. All rights reserved.
//

#import "AGPhotoBrowserViewController.h"
#import "AGPhotoBrowserOverlayView.h"
#import "AGPhotoBrowserZoomableView.h"
#import "AGPhotoBrowserCell.h"

@interface AGPhotoBrowserViewController () <UICollectionViewDataSource,	UICollectionViewDelegateFlowLayout, AGPhotoBrowserOverlayViewDelegate, AGPhotoBrowserCellDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) AGPhotoBrowserOverlayView *overlayView;
@property (nonatomic, strong) AGPhotoBrowser *photoBrowser;

@property (nonatomic, assign) NSInteger currentlySelectedIndex;
@property (nonatomic, assign) CGPoint startingPanPoint;
@property (nonatomic, assign, getter = isDisplayingDetailedView) BOOL displayingDetailedView;


@end

@implementation AGPhotoBrowserViewController

NSString * const AGPhotoBrowserViewControllerCellIdentifier = @"AGPhotoBrowserCell";
const NSInteger AGPhotoBrowserThresholdToCenter = 150;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	return [self initWithPhotoBrowser:nil];
}

- (instancetype)initWithPhotoBrowser:(AGPhotoBrowser *)photoBrowser
{
	NSParameterAssert(photoBrowser);
	
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		// Custom initialization
		_photoBrowser = photoBrowser;
	}
	return self;
}

- (void)loadView
{
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view.backgroundColor = [UIColor clearColor];
	
	[self.view addSubview:self.collectionView];
	[self.view addSubview:self.overlayView];
	
	[self p_buildConstraints];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Getters

- (UICollectionView *)collectionView
{
	if (!_collectionView) {
		UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
		flowLayout.minimumInteritemSpacing = 0;
		flowLayout.minimumLineSpacing = 0;
		flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		
		_collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
		_collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		_collectionView.dataSource = self;
		_collectionView.delegate = self;
		_collectionView.backgroundColor = [UIColor clearColor];
		_collectionView.pagingEnabled = YES;
		_collectionView.showsVerticalScrollIndicator = NO;
		_collectionView.showsHorizontalScrollIndicator = NO;
		
		Class cellClass;
		if ([self.dataSource respondsToSelector:@selector(cellClassForPhotoBrowser:)]) {
			cellClass = [self.dataSource cellClassForPhotoBrowser:self.photoBrowser];
		} else {
			cellClass = [AGPhotoBrowserCell class];
		}
		[_collectionView registerClass:cellClass forCellWithReuseIdentifier:AGPhotoBrowserViewControllerCellIdentifier];
	}
	
	return _collectionView;
}

- (AGPhotoBrowserOverlayView *)overlayView
{
	if (!_overlayView) {
		_overlayView = [[AGPhotoBrowserOverlayView alloc] initWithFrame:CGRectZero];
		_overlayView.translatesAutoresizingMaskIntoConstraints = NO;
        _overlayView.delegate = self;
	}
	
	return _overlayView;
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

#pragma mark - Private methods

- (void)p_buildConstraints
{
	NSDictionary *constrainedViews = NSDictionaryOfVariableBindings(_collectionView, _overlayView);
	NSDictionary *metrics = @{};

	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_collectionView]|" options:0 metrics:metrics views:constrainedViews]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_overlayView]|" options:0 metrics:metrics views:constrainedViews]];

	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_collectionView]|" options:0 metrics:metrics views:constrainedViews]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_overlayView]|" options:0 metrics:metrics views:constrainedViews]];
}

- (void)p_setupPhotoForIndex:(NSInteger)index
{
    self.currentlySelectedIndex = index;
	
    if ([self.dataSource respondsToSelector:@selector(photoBrowser:willDisplayActionButtonAtIndex:)]) {
        self.overlayView.actionButton.hidden = ![self.dataSource photoBrowser:nil willDisplayActionButtonAtIndex:self.currentlySelectedIndex];
    } else {
        self.overlayView.actionButton.hidden = NO;
    }
    
	if ([self.dataSource respondsToSelector:@selector(photoBrowser:titleForImageAtIndex:)]) {
		self.overlayView.photoTitle = [self.dataSource photoBrowser:nil titleForImageAtIndex:self.currentlySelectedIndex];
	} else {
        self.overlayView.photoTitle = @"";
    }
	
	if ([self.dataSource respondsToSelector:@selector(photoBrowser:descriptionForImageAtIndex:)]) {
		self.overlayView.photoDescription = [self.dataSource photoBrowser:nil descriptionForImageAtIndex:self.currentlySelectedIndex];
	} else {
        self.overlayView.photoDescription = @"";
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.dataSource numberOfPhotosForPhotoBrowser:nil];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell<AGPhotoBrowserCellProtocol> *cell = [collectionView dequeueReusableCellWithReuseIdentifier:AGPhotoBrowserViewControllerCellIdentifier forIndexPath:indexPath];
	cell.delegate = self;
	
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UICollectionViewCell<AGPhotoBrowserCellProtocol> *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.dataSource respondsToSelector:@selector(photoBrowser:shouldDisplayOverlayViewAtIndex:)]) {
		BOOL overlayIsVisible = [self.dataSource photoBrowser:self.photoBrowser shouldDisplayOverlayViewAtIndex:indexPath.row];
		self.overlayView.hidden = !overlayIsVisible;
	}
	
    if ([cell respondsToSelector:@selector(resetZoomScale)]) {
        [cell resetZoomScale];
    }
    
    if ([self.dataSource respondsToSelector:@selector(photoBrowser:URLStringForImageAtIndex:)] && [cell respondsToSelector:@selector(setCellImageWithURL:)]) {
        [cell setCellImageWithURL:[NSURL URLWithString:[self.dataSource photoBrowser:self.photoBrowser URLStringForImageAtIndex:indexPath.row]]];
    } else if ([self.dataSource respondsToSelector:@selector(photoBrowser:imageAtIndex:)]) {
        [cell setCellImage:[self.dataSource photoBrowser:nil imageAtIndex:indexPath.row]];
    }
}

#pragma mark - UICollectionViewFlowLayoutDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	self.displayingDetailedView = !self.isDisplayingDetailedView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return self.view.bounds.size;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    if (!self.currentWindow.hidden && !self.changingOrientation) {
//        CGPoint targetContentOffset = scrollView.contentOffset;
//        
//        UITableView *tv = (UITableView*)scrollView;
//        NSIndexPath *indexPathOfTopRowAfterScrolling = [tv indexPathForRowAtPoint:targetContentOffset];
//		
//        [self p_setupPhotoForIndex:indexPathOfTopRowAfterScrolling.row];
//    }
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

#pragma mark - AGPhotoBrowserOverlayViewDelegate

- (void)sharingView:(AGPhotoBrowserOverlayView *)sharingView didTapOnActionButton:(UIButton *)actionButton
{
	if ([self.delegate respondsToSelector:@selector(photoBrowser:didTapOnActionButton:atIndex:)]) {
		[self.delegate photoBrowser:nil didTapOnActionButton:actionButton atIndex:self.currentlySelectedIndex];
	}
}

#pragma mark - Recognizers

- (void)p_imageViewPanned:(UIPanGestureRecognizer *)recognizer
{
//	AGPhotoBrowserZoomableView *imageView = (AGPhotoBrowserZoomableView *)recognizer.view;
//	
//	if (recognizer.state == UIGestureRecognizerStateBegan) {
//		// -- Disable table view scrolling
//		self.collectionView.scrollEnabled = NO;
//		// -- Hide detailed view
//		self.displayingDetailedView = NO;
//		_startingPanPoint = imageView.center;
//		return;
//	}
//	
//	if (recognizer.state == UIGestureRecognizerStateEnded) {
//		// -- Enable table view scrolling
//		self.collectionView.scrollEnabled = YES;
//		// -- Check if user dismissed the view
//		CGPoint endingPanPoint = [recognizer translationInView:self.view];
//		CGPoint translatedPoint = CGPointMake(_startingPanPoint.x + endingPanPoint.x, _startingPanPoint.y);
//		
//		imageView.center = translatedPoint;
//		int heightDifference = abs(floor(_startingPanPoint.x - translatedPoint.x));
//		
//		if (heightDifference <= AGPhotoBrowserThresholdToCenter) {
//			// -- Back to original center
//			[UIView animateWithDuration:AGPhotoBrowserAnimationDuration
//							 animations:^(){
//								 self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:1.];
//								 imageView.center = self->_startingPanPoint;
//							 } completion:^(BOOL finished){
//								 // -- show detailed view?
//								 self.displayingDetailedView = YES;
//							 }];
//		} else {
//			// -- Animate out!
//			typeof(self) weakSelf __weak = self;
//			[self hideAnimated:YES completion:^(BOOL finished){
//				typeof(weakSelf) strongSelf __strong = weakSelf;
//				if (strongSelf) {
//					imageView.center = strongSelf->_startingPanPoint;
//				}
//			}];
//		}
//	} else {
//		CGPoint middlePanPoint = [recognizer translationInView:self.view];
//		CGPoint translatedPoint = CGPointMake(_startingPanPoint.x + middlePanPoint.x, self.startingPanPoint.y);
//		
//		imageView.center = translatedPoint;
//		int heightDifference = abs(floor(self.startingPanPoint.x - translatedPoint.x));
//		CGFloat ratio = (self.startingPanPoint.x - heightDifference)/self.startingPanPoint.x;
//		self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:ratio];
//	}
}

@end
