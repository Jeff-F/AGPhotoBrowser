//
//  AGPhotoBrowserOverlayView.m
//  AGPhotoBrowser
//
//  Created by Andrea Giavatto on 7/28/13.
//  Copyright (c) 2013 Andrea Giavatto. All rights reserved.
//

#import "AGPhotoBrowserOverlayView.h"
#import "AGPhotoBrowserGradientView.h"
#import <QuartzCore/QuartzCore.h>


@interface AGPhotoBrowserOverlayView () {
	BOOL _animated;
    NSInteger _descriptionLabelHeight;	
}

@property (nonatomic, strong) AGPhotoBrowserGradientView *sharingView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *resetGesture;

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *descriptionLabel;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UIButton *seeMoreButton;
@property (nonatomic, strong, readwrite) UIButton *actionButton;

@property (nonatomic, assign, readwrite, getter = isVisible) BOOL visible;

@end


@implementation AGPhotoBrowserOverlayView

const NSInteger AGOverlayMargin = 20;
const NSInteger AGInitialDescriptionHeight = 32;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self p_setupView];
    }
    return self;
}

- (void)p_setupView
{
	self.alpha = 0;
	_descriptionLabelHeight = AGInitialDescriptionHeight;
    
	[self.sharingView addSubview:self.titleLabel];
	[self.sharingView addSubview:self.separatorView];
	[self.sharingView addSubview:self.descriptionLabel];
	[self.sharingView addSubview:self.seeMoreButton];
	[self.sharingView addSubview:self.actionButton];
	[self.sharingView addGestureRecognizer:self.resetGesture];
	
	[self addSubview:self.sharingView];
	[self addGestureRecognizer:self.tapGesture];
}

- (void)updateConstraints
{
	[self removeConstraints:self.constraints];
	
	NSDictionary *constrainedViews = NSDictionaryOfVariableBindings(_sharingView, _titleLabel, _separatorView, _descriptionLabel, _seeMoreButton, _actionButton);
	NSDictionary *metrics = @{@"SharingViewHeight" : @(_descriptionLabelHeight + 130), @"DescriptionLabelHeight" : @(_descriptionLabelHeight), @"AGOverlayMargin" : @(AGOverlayMargin)};
	
	// -- Horizontal constraints
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_sharingView]|" options:0 metrics:metrics views:constrainedViews]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==AGOverlayMargin)-[_titleLabel]-(==AGOverlayMargin)-|" options:0 metrics:metrics views:constrainedViews]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==AGOverlayMargin)-[_separatorView]-(==AGOverlayMargin)-|" options:0 metrics:metrics views:constrainedViews]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==AGOverlayMargin)-[_descriptionLabel]-(==AGOverlayMargin)-|" options:0 metrics:metrics views:constrainedViews]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[_seeMoreButton(==60)]-(==AGOverlayMargin)-|" options:0 metrics:metrics views:constrainedViews]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[_actionButton(==60)]-(==10)-|" options:0 metrics:metrics views:constrainedViews]];
	
	// -- Vertical constraints
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[_sharingView(==SharingViewHeight)]|" options:0 metrics:metrics views:constrainedViews]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==30)-[_titleLabel(==20)]-[_separatorView(==1)]-[_descriptionLabel(==DescriptionLabelHeight)][_seeMoreButton(==25)][_actionButton(==30)]-(>=0)-|" options:0 metrics:metrics views:constrainedViews]];
	
	[super updateConstraints];
}


#pragma mark - Public methods

- (void)setOverlayVisible:(BOOL)visible animated:(BOOL)animated
{
	_animated = animated;
    self.visible = visible;
}

//- (void)resetOverlayView
//{
//    self.descriptionExpanded = NO;
//    
//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    
//    CGRect frame = self.superview.frame;
//    CGRect overlayFrame = CGRectZero;
//    if (UIDeviceOrientationIsPortrait(orientation) || !UIDeviceOrientationIsLandscape(orientation)) {
//        overlayFrame = CGRectMake(0, CGRectGetHeight(frame) - AGPhotoBrowserOverlayInitialHeight, CGRectGetWidth(frame), AGPhotoBrowserOverlayInitialHeight);
//    } else if (orientation == UIDeviceOrientationLandscapeLeft) {
//        overlayFrame = CGRectMake(0, 0, AGPhotoBrowserOverlayInitialHeight, CGRectGetHeight(frame));
//    } else {
//        overlayFrame = CGRectMake(CGRectGetWidth(frame) - AGPhotoBrowserOverlayInitialHeight, 0, AGPhotoBrowserOverlayInitialHeight, CGRectGetHeight(frame));
//    }
//    
//    [UIView animateWithDuration:0.15
//                     animations:^(){
//                         self.frame = overlayFrame;
//                     }];
//}


#pragma mark - Private methods

- (CGSize)p_sizeForDescriptionLabel
{
    CGFloat newDescriptionWidth = CGRectGetWidth(self.bounds) - 2*20;
    
    CGSize descriptionSize;
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        descriptionSize = [self.photoDescription sizeWithFont:self.descriptionLabel.font constrainedToSize:CGSizeMake(newDescriptionWidth, MAXFLOAT)];
    } else {
        NSDictionary *textAttributes = @{NSFontAttributeName : self.descriptionLabel.font};
        CGRect descriptionBoundingRect = [self.photoDescription boundingRectWithSize:CGSizeMake(newDescriptionWidth, MAXFLOAT)
                                                                        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:textAttributes
                                                                        context:nil];
        descriptionSize = CGSizeMake(ceil(CGRectGetWidth(descriptionBoundingRect)), ceil(CGRectGetHeight(descriptionBoundingRect)));
    }
    
    return descriptionSize;
}

#pragma mark - Buttons

- (void)p_actionButtonTapped:(UIButton *)sender
{
	if ([self.delegate respondsToSelector:@selector(sharingView:didTapOnActionButton:)]) {
		[self.delegate sharingView:self didTapOnActionButton:sender];
	}
}

- (void)p_seeMoreButtonTapped:(UIButton *)sender
{
	if ([self.delegate respondsToSelector:@selector(sharingView:didTapOnSeeMoreButton:)]) {
		[self.delegate sharingView:self didTapOnSeeMoreButton:sender];
	}
	
    self.seeMoreButton.hidden = YES;
    
    CGSize newDescriptionSize = [self p_sizeForDescriptionLabel];
	_descriptionLabelHeight = newDescriptionSize.height;
	[self updateConstraints];

    [UIView animateWithDuration:AGPhotoBrowserAnimationDuration
                     animations:^(){
                         [self layoutIfNeeded];
                     }];
}


#pragma mark - Recognizers

- (void)p_tapGestureTapped:(UITapGestureRecognizer *)recognizer
{
	self.visible = !self.visible;
}

- (void)p_resetGestureTapped:(UITapGestureRecognizer *)recognizer
{
	_descriptionLabelHeight = AGInitialDescriptionHeight;
	[self updateConstraints];
	
	[UIView animateWithDuration:AGPhotoBrowserAnimationDuration
					 animations:^{
						 [self layoutIfNeeded];
					 }
					 completion:^(BOOL finished) {
						 self.seeMoreButton.hidden = NO;
					 }];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	if ([self.seeMoreButton pointInside:[self convertPoint:point toView:self.seeMoreButton] withEvent:event]) {
        return self.seeMoreButton;
    }
	if ([self.actionButton pointInside:[self convertPoint:point toView:self.actionButton] withEvent:event]) {
        return self.actionButton;
    }
	if ([self.sharingView pointInside:[self convertPoint:point toView:self.sharingView] withEvent:event]) {
        return self.sharingView;
    }
	
    return nil;
}


#pragma mark - Setters

- (void)setVisible:(BOOL)visible
{
	_visible = visible;
	
	CGFloat newAlpha = _visible ? 1. : 0.;
	[UIView animateWithDuration:AGPhotoBrowserAnimationDuration
					 animations:^(){
						 self.alpha = newAlpha;
					 }];
}

- (void)setPhotoTitle:(NSString *)title
{
	_photoTitle = title;
	
	self.titleLabel.text = _photoTitle.length ? _photoTitle : @"";
}

- (void)setPhotoDescription:(NSString *)photoDescription
{
	_photoDescription = photoDescription;
	
	self.descriptionLabel.text = _photoDescription.length ? _photoDescription : @"";
}


#pragma mark - Getters

- (AGPhotoBrowserGradientView *)sharingView
{
	if (!_sharingView) {
		_sharingView = [[AGPhotoBrowserGradientView alloc] initWithFrame:CGRectZero];
		_sharingView.translatesAutoresizingMaskIntoConstraints = NO;
		_sharingView.backgroundColor = [UIColor clearColor];

		_sharingView.layer.colors = [NSArray arrayWithObjects:(id)[[UIColor clearColor] CGColor], (id)[[UIColor blackColor] CGColor], nil];
	}
	
	return _sharingView;
}

- (UILabel *)titleLabel
{
	if (!_titleLabel) {
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_titleLabel.textColor = [UIColor colorWithWhite:0.9 alpha:0.9];
		_titleLabel.font = [UIFont boldSystemFontOfSize:14];
		_titleLabel.backgroundColor = [UIColor clearColor];
	}
	
	return _titleLabel;
}

- (UIView *)separatorView
{
	if (!_separatorView) {
		_separatorView = [[UIView alloc] initWithFrame:CGRectZero];
		_separatorView.translatesAutoresizingMaskIntoConstraints = NO;
		_separatorView.backgroundColor = [UIColor lightGrayColor];
//        _separatorView.hidden = YES;
	}
	
	return _separatorView;
}

- (UILabel *)descriptionLabel
{
	if (!_descriptionLabel) {
		_descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_descriptionLabel.textColor = [UIColor colorWithWhite:0.9 alpha:0.9];
		_descriptionLabel.font = [UIFont systemFontOfSize:13];
		_descriptionLabel.backgroundColor = [UIColor clearColor];
		_descriptionLabel.numberOfLines = 0;
	}
	
	return _descriptionLabel;
}

- (UIButton *)seeMoreButton
{
	if (!_seeMoreButton) {
		_seeMoreButton = [[UIButton alloc] initWithFrame:CGRectZero];
		_seeMoreButton.translatesAutoresizingMaskIntoConstraints = NO;
		[_seeMoreButton setTitle:NSLocalizedString(@"See More", @"Title for See more button") forState:UIControlStateNormal];
		[_seeMoreButton setBackgroundColor:[UIColor clearColor]];
		[_seeMoreButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
		_seeMoreButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
//        _seeMoreButton.hidden = YES;
		
		[_seeMoreButton addTarget:self action:@selector(p_seeMoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	}
	
	return _seeMoreButton;
}

- (UIButton *)actionButton
{
	if (!_actionButton) {
		_actionButton = [[UIButton alloc] initWithFrame:CGRectZero];
		_actionButton.translatesAutoresizingMaskIntoConstraints = NO;
		[_actionButton setTitle:NSLocalizedString(@"● ● ●", @"Title for Action button") forState:UIControlStateNormal];
		[_actionButton setBackgroundColor:[UIColor clearColor]];
		[_actionButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateNormal];
		[_actionButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateHighlighted];
		[_actionButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        
		[_actionButton addTarget:self action:@selector(p_actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	}
	
	return _actionButton;
}

- (UITapGestureRecognizer *)tapGesture
{
	if (!_tapGesture) {
		_tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_tapGestureTapped:)];
		_tapGesture.numberOfTouchesRequired = 1;
	}
	
	return _tapGesture;
}

- (UITapGestureRecognizer *)resetGesture
{
	if (!_resetGesture) {
		_resetGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_resetGestureTapped:)];
		_resetGesture.numberOfTouchesRequired = 1;
	}
	
	return _resetGesture;
}

@end
