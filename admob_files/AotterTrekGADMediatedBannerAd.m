//
//  AotterTrekGADMediatedBannerAd.m
//  AotterServiceTest
//
//  Created by Aotter superwave on 2022/8/23.
//  Copyright © 2022 Aotter. All rights reserved.
//

#import "AotterTrekGADMediatedBannerAd.h"

@interface AotterTrekGADMediatedBannerAd()<TKAdSuprAdDelegate>
@property TKAdSuprAd *suprAd;
@property(nonatomic, copy) NSMutableDictionary *extras;
//@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
//@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, strong) UIView *mediaView;
@property CGFloat preferedAdWidth;
@property CGFloat preferedAdHeight;

@end

@implementation AotterTrekGADMediatedBannerAd
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
        
        self.preferedAdWidth = preferedAdSize.width;
        self.preferedAdHeight = preferedAdSize.height;
        NSNumber *adWidth = [NSNumber numberWithDouble:preferedAdSize.width];
        NSNumber *adHeight = [NSNumber numberWithDouble:preferedAdSize.height];
        
        [_extras setObject:adWidth forKey:@"adSizeWidth"];
        [_extras setObject:adHeight forKey:@"adSizeHeight"];
        
        
//        NSString *iconImageUrlString = _suprAd.adData[kTKAdImage_iconKey];
//        NSURL *iconImageURL = [[NSURL alloc] initWithString:iconImageUrlString];
//        GADNativeAdImage *iconImage = [[GADNativeAdImage alloc] initWithURL:iconImageURL scale:1];
//
//        NSString *iconHDImageUrlString = _suprAd.adData[kTKAdImage_icon_hdKey];
//        NSURL *iconHDImageURL = [[NSURL alloc] initWithString:iconHDImageUrlString];
//        GADNativeAdImage *iconHDImage = [[GADNativeAdImage alloc] initWithURL:iconHDImageURL scale:1];
//
//        NSString *mainImageUrlString = _suprAd.adData[kTKAdImage_mainKey];
//        NSURL *mainImageURL = [[NSURL alloc] initWithString:mainImageUrlString];
//        GADNativeAdImage *mainImage = [[GADNativeAdImage alloc] initWithURL:mainImageURL scale:1];
        
//        self.mappedImages = @[iconImage,iconHDImage,mainImage];
//        _mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconHDImageURL scale:1];
        
        
//        [_extras setObject:iconImageUrlString forKey:kTKAdImage_iconKey];
//        [_extras setObject:iconHDImageUrlString forKey:kTKAdImage_icon_hdKey];
//        [_extras setObject:mainImageUrlString forKey:kTKAdImage_mainKey];
        
        [_extras addEntriesFromDictionary:_suprAd.adData];
        
        // register SuprAd MediaView
        CGFloat viewWidth = UIScreen.mainScreen.bounds.size.width;
        CGFloat viewHeight = viewWidth * preferedAdSize.height/preferedAdSize.width;
        int height = (int)viewHeight;
        
        _mediaView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, height)];
        [_suprAd registerTKMediaView:_mediaView];
        [_suprAd loadAd];
        
    }
    return self;
}

-(UIView *)view{
    return _mediaView;
}

-(void)changeAdSizeTo:(GADAdSize)adSize{
    
}


@end
