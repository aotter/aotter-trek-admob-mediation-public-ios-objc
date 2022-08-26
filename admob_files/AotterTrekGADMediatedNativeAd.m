//
//  TrekGADMediatedNativeAd.m
//  GoogleMediation
//
//  Created by JustinTsou on 2020/12/11.
//

#import "AotterTrekGADMediatedNativeAd.h"

@interface AotterTrekGADMediatedNativeAd()<TKAdNativeDelegate>

@property TKAdNative *nativeAd;
@property(nonatomic, copy) NSMutableDictionary *extras;
@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, strong) UIImageView *mainImageView;

@end


@implementation AotterTrekGADMediatedNativeAd

- (instancetype)initWithTKNativeAd:(nonnull TKAdNative *)nativeAd withAdPlace:(NSString *)adPlace {
    if(!nativeAd.AdData){
        return nil;
    }
    
    self = [super init];
    if (self) {
        _nativeAd = nativeAd;
        _nativeAd.delegate = self;
        _extras = [[NSMutableDictionary alloc] init];
        [_extras setObject:@"nativeAd" forKey:@"trekAd"];
        [_extras setObject:adPlace forKey:@"adPlace"];
        
        
        NSString *iconImageUrlString = _nativeAd.AdData[kTKAdImage_iconKey];
        NSURL *iconImageURL = [[NSURL alloc] initWithString:iconImageUrlString];
        GADNativeAdImage *iconImage = [[GADNativeAdImage alloc] initWithURL:iconImageURL scale:1];
        
        NSString *iconHDImageUrlString = _nativeAd.AdData[kTKAdImage_icon_hdKey];
        NSURL *iconHDImageURL = [[NSURL alloc] initWithString:iconHDImageUrlString];
        GADNativeAdImage *iconHDImage = [[GADNativeAdImage alloc] initWithURL:iconHDImageURL scale:1];
        
        NSString *mainImageUrlString = _nativeAd.AdData[kTKAdImage_mainKey];
        NSURL *mainImageURL = [[NSURL alloc] initWithString:mainImageUrlString];
        GADNativeAdImage *mainImage = [[GADNativeAdImage alloc] initWithURL:mainImageURL scale:1];
        if([mainImageUrlString length] > 0){
            _mainImageView = [[UIImageView alloc] init];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:mainImageURL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _mainImageView.image = [UIImage imageWithData:data];
                });
            });
        }
        
        self.mappedImages = @[iconImage,iconHDImage,mainImage];
        _mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconHDImageURL scale:1];
        
        [_extras setObject:iconImageUrlString forKey:kTKAdImage_iconKey];
        [_extras setObject:iconHDImageUrlString forKey:kTKAdImage_icon_hdKey];
        [_extras setObject:mainImageUrlString forKey:kTKAdImage_mainKey];
        
        [_extras addEntriesFromDictionary:_nativeAd.AdData];
        
    }
    return self;
}


#pragma mark - GADMediatedUnifiedNativeAd

- (BOOL)hasVideoContent {
    return _mainImageView != nil? YES:NO;
}

- (UIView *)mediaView {
    return _mainImageView;
}

- (NSString *)advertiser {
    return _nativeAd.AdData[kTKAdAdvertiserNameKey];
}

- (NSString *)headline {
    return _nativeAd.AdData[kTKAdTitleKey];
}

- (NSArray *)images {
    return self.mappedImages;
}

- (NSString *)body {
    return _nativeAd.AdData[kTKAdTextKey];
}

- (GADNativeAdImage *)icon {
    return self.mappedIcon;
}

- (NSString *)callToAction {
    return _nativeAd.AdData[kTKAdCall_to_actionKey];
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

-(BOOL)handlesUserClicks{
    return YES;
}

-(BOOL)handlesUserImpressions{
    return YES;
}

- (void)didRenderInView:(UIView *)view clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)clickableAssetViews nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)nonclickableAssetViews viewController:(UIViewController *)viewController {
    [_nativeAd registerAdView:view];
    [_nativeAd registerPresentingViewController:viewController];
}

- (void)didUntrackView:(UIView *)view{
    [_nativeAd destroy];
}


#pragma mark - TKAdNativeDelegate

- (void)TKAdNativeWillLogClicked:(TKAdNative *)ad {
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];
}

-(void)TKAdNativeWillLogImpression:(TKAdNative *)ad{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

@end
