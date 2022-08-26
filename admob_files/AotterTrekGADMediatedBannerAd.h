//
//  AotterTrekGADMediatedBannerAd.h
//  AotterServiceTest
//
//  Created by Aotter superwave on 2022/8/23.
//  Copyright © 2022 Aotter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>


#if devmode
    #import "TKAdSuprAd.h"
    #import "TKNativeAdConstant.h"
#else
    #import <AotterTrek-iOS-SDK/AotterTrek-iOS-SDK.h>
#endif


NS_ASSUME_NONNULL_BEGIN

@interface AotterTrekGADMediatedBannerAd : NSObject<GADMediationBannerAd>
- (instancetype _Nullable )initWithTKSuprAd:(nonnull TKAdSuprAd *)suprAd withAdPlace:(NSString *)adPlace withAdSize:(CGSize)preferedAdSize;

NS_ASSUME_NONNULL_END

@end

