//
//  CTDownloadImageView.m
//  CBSWallet
//
//  Created by yaoyongping on 12-11-22.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "CTDownloadImageView.h"

NSString * DEFAULT_EMPTY_IMAGE = @"defaultEmptyImage.png";

UIColor * DEFAULT_BACKGROUNDCOLOR;

@implementation CTDownloadImageView
@synthesize _activityView;
@synthesize _contentMode;
@synthesize _defaultImage;
@synthesize _emptyImage;
@synthesize _imageView;
@synthesize _isLoadingImage;
@synthesize _webService;
@synthesize _emptyOrDefaultContentMode;
@synthesize _delegate;
@synthesize _url;
@synthesize _defaultColor;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self._defaultColor = DEFAULT_BACKGROUNDCOLOR;
        self._emptyOrDefaultContentMode = UIViewContentModeScaleAspectFit;
        self._contentMode = UIViewContentModeScaleToFill;
        self._emptyImage = [UIImage imageNamed:DEFAULT_EMPTY_IMAGE];
        
		self._imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)] autorelease];
		[self addSubview:self._imageView];
        [self setBackgroundColor:DEFAULT_BACKGROUNDCOLOR];
        self._imageView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
     
        [self setImage:self._emptyImage];
        
        //指示器
        UIActivityIndicatorView *activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
        CGRect activityViewFrame = activityView.frame;
        activityViewFrame.origin.x = (frame.size.width - activityViewFrame.size.width) / 2;
        activityViewFrame.origin.y = (frame.size.height - activityViewFrame.size.height) / 2;
        activityView.frame = activityViewFrame;
        activityView.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        
        activityView.autoresizingMask = TRUE;
        self._activityView = activityView;
        [self addSubview:activityView];
        //
        self._webService = [[[CTWebService alloc] init] autorelease];
        self._webService._delegate = self;
        //
        self.backgroundColor = [UIColor clearColor];
        self._imageView.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)dealloc
{
    NSLog(@"custom imageView dealloc");
    
    [self cancelLoad];
    self._url = 0;
    self._defaultColor = 0;
    self._webService._delegate = 0;
    self._webService = 0;
    self._activityView = 0;
    self._defaultImage = 0;
    self._emptyImage = 0;
    self._imageView = 0;
    [super dealloc];
}
-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    CGRect activityViewFrame = self._activityView.frame;
    activityViewFrame.origin.x = (frame.size.width - activityViewFrame.size.width) / 2;
    activityViewFrame.origin.y = (frame.size.height - activityViewFrame.size.height) / 2;
    self._activityView.frame = activityViewFrame;
    //
    self._imageView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}
-(void)cancelLoad
{
    if([self._webService isWorking])
    {
        [self._webService cancelLoading];
        [self jobsAfterDone];
    }
}
-(void)setImage:(UIImage *)img
{
    [self cancelLoad];
    [self setBackgroundColor:[UIColor clearColor]];
	if(img == self._emptyImage || img == self._defaultImage)
    {
        [self._imageView setContentMode:self._emptyOrDefaultContentMode];
        self._imageView.backgroundColor = self._defaultColor;
    }
    else
    {
        [self._imageView setContentMode:self._contentMode];
        self._imageView.backgroundColor = [UIColor clearColor];//背景透明
    }
    self._imageView.image = img;
}

-(BOOL)_isLoadingImage
{
    return [self._webService isWorking];
}
-(void)loadImage:(NSString *)imageUrl
{
    [self cancelLoad];
    NSLog(@"image URL=%@",imageUrl);
    NSString *md5Imagename = [CTUtility MD5Encode:imageUrl];
    UIImage * image = [CTUtility getCacheImageWithImageName:md5Imagename];
    if (image)
    {
        [self setImage:image];
    }
    else
    {
        [self jobsBeforeStart];
        self._url = imageUrl;
        [self._webService startWithUrl:self._url];
    }

}

-(void)jobsBeforeStart
{
    [self setImage:self._defaultImage];
    [_activityView startAnimating];
}
-(void)jobsAfterDone
{
    self._url = 0;
    [self._activityView stopAnimating];
}

#pragma mark CTWebServiceDelegate
-(void)beforWebServiceStart:(CTWebService*)engine
{
    //
}
-(void)afterWebServiceEnd:(CTWebService*)engine
{
    if(engine._lastExecutionResult == Result_Succeed)
    {
        UIImage *image = [UIImage imageWithData:engine.data];
        NSString *imagename = [CTUtility MD5Encode:self._url];
        [CTUtility cacheImageWithName:imagename image:image];
        
        if (self._delegate)
        {
            [self._delegate afterDownImageViewSucceed:self image:image url:self._url];
        }
        [self setImage:image];
    }
    else if(engine._lastExecutionResult == Result_Error)
    {
        [self setImage:self._defaultImage];
    }
    else if(engine._lastExecutionResult == Result_Canceld)
    {
        [self setImage:self._emptyImage];
    }
    else
    {
        //nothing
    }
    [self jobsAfterDone];

}
@end
