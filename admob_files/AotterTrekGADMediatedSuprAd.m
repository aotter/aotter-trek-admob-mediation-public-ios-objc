//
//  AotterTrekGADMediatedSuprAd.m
//  GoogleMediation
//
//  Created by JustinTsou on 2020/12/14.
//

#import "AotterTrekGADMediatedSuprAd.h"

@interface AotterTrekGADMediatedSuprAd ()<TKAdSuprAdDelegate>

@property TKAdSuprAd *suprAd;
@property(nonatomic, copy) NSMutableDictionary *extras;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, strong) UIView *mediaView;

@end

@implementation AotterTrekGADMediatedSuprAd

- (instancetype _Nullable )initWithTKSuprAd:(nonnull TKAdSuprAd *)suprAd withAdPlace:(NSString *)adPlace withAdSize:(CGSize)preferedAdSize {
    
    if(!suprAd.adData){
        return nil;
    }
    
    self = [super init];
    if (self) {
        _suprAd = suprAd;
        _suprAd.delegate = self;
        _extras = [[NSMutableDictionary alloc] init];
        [_extras setObject:@"suprAd" forKey:@"trekAd"];
        [_extras setObject:adPlace forKey:@"adPlace"];
        
        NSNumber *adWidth = [NSNumber numberWithDouble:preferedAdSize.width];
        NSNumber *adHeight = [NSNumber numberWithDouble:preferedAdSize.height];
        
        [_extras setObject:adWidth forKey:@"adSizeWidth"];
        [_extras setObject:adHeight forKey:@"adSizeHeight"];
        
        
        NSString *iconImageUrlString = _suprAd.adData[kTKAdImage_iconKey];
        NSURL *iconImageURL = [[NSURL alloc] initWithString:iconImageUrlString];
        GADNativeAdImage *iconImage = [[GADNativeAdImage alloc] initWithURL:iconImageURL scale:1];
        
        NSString *iconHDImageUrlString = _suprAd.adData[kTKAdImage_icon_hdKey];
        NSURL *iconHDImageURL = [[NSURL alloc] initWithString:iconHDImageUrlString];
        GADNativeAdImage *iconHDImage = [[GADNativeAdImage alloc] initWithURL:iconHDImageURL scale:1];
        
        NSString *mainImageUrlString = _suprAd.adData[kTKAdImage_mainKey];
        NSURL *mainImageURL = [[NSURL alloc] initWithString:mainImageUrlString];
        GADNativeAdImage *mainImage = [[GADNativeAdImage alloc] initWithURL:mainImageURL scale:1];
        
        self.mappedImages = @[iconImage,iconHDImage,mainImage];
        _mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconHDImageURL scale:1];
        
        
        [_extras setObject:iconImageUrlString forKey:kTKAdImage_iconKey];
        [_extras setObject:iconHDImageUrlString forKey:kTKAdImage_icon_hdKey];
        [_extras setObject:mainImageUrlString forKey:kTKAdImage_mainKey];
        
        [_extras addEntriesFromDictionary:_suprAd.adData];
        
        // register SuprAd MediaView
        
        [self registerSuprAdMediaView:preferedAdSize];
        
    }
    return self;
}


- (BOOL)hasVideoContent {
    return _mediaView != nil ? YES:NO;
}

- (UIView *)mediaView {
    return _mediaView;
}

- (NSString *)advertiser {
    return _suprAd.adData[kTKAdAdvertiserNameKey];
}

- (NSString *)headline {
  return _suprAd.adData[kTKAdTitleKey];
}

- (NSArray *)images {
    return self.mappedImages;
}

- (NSString *)body {
  return _suprAd.adData[kTKAdTextKey];
}

- (GADNativeAdImage *)icon {
  return self.mappedIcon;
}

- (NSString *)callToAction {
  return _suprAd.adData[kTKAdCall_to_actionKey];
}

- (NSDecimalNumber *)starRating {
  return nil;
}

- (NSString *)store {
  return nil;
}

- (NSString *)price {
  return nil;
}

- (NSDictionary *)extraAssets {
  return self.extras;
}

- (UIView *)adChoicesView {
  return nil;
}

- (void)TKAdSuprAdWillLogImpression:(TKAdSuprAd *)ad {
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)TKAdSuprAdWillLogClick:(TKAdSuprAd *)ad {
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];
}


#pragma mark - Private Method

- (void)registerSuprAdMediaView:(CGSize)preferedAdSize {
    
    CGFloat viewWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat viewHeight = viewWidth * preferedAdSize.height/preferedAdSize.width;
    int height = (int)viewHeight;
    
    _mediaView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, height)];
    [_suprAd registerTKMediaView:_mediaView];
    [_suprAd loadAd];
}

-(void)didRenderInView:(UIView *)view clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)clickableAssetViews nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)nonclickableAssetViews viewController:(UIViewController *)viewController{
    NSLog(@"QQQQQQ");
    [_suprAd registerAdView:view];
}

@end

