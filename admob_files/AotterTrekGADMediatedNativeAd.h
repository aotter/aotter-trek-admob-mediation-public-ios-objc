//
//  TrekGADMediatedNativeAd.h
//  GoogleMediation
//
//  Created by JustinTsou on 2020/12/11.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#if devmode
    #import "TKAdNative.h"
    #import "TKNativeAdConstant.h"
#else
    #import <AotterTrek-iOS-SDK/AotterTrek-iOS-SDK.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AotterTrekGADMediatedNativeAd : NSObject<GADMediationNativeAd>

- (instancetype)initWithTKNativeAd:(nonnull TKAdNative *)nativeAd withAdPlace:(NSString *)adPlace;

@end

NS_ASSUME_NONNULL_END
