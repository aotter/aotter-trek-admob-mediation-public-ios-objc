//
//  TrekGADMediatedNativeAd.h
//  GoogleMediation
//
//  Created by JustinTsou on 2020/12/11.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AotterTrek-iOS-SDK/AotterTrek-iOS-SDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface AotterTrekGADMediatedNativeAd : NSObject<GADMediatedUnifiedNativeAd>

- (instancetype)initWithTKNativeAd:(nonnull TKAdNative *)nativeAd withAdPlace:(NSString *)adPlace;

@end

NS_ASSUME_NONNULL_END
