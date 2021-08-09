//
//  AotterTrekGADMediatedSuprAd.h
//  GoogleMediation
//
//  Created by JustinTsou on 2020/12/14.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AotterTrek-iOS-SDK/AotterTrek-iOS-SDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface AotterTrekGADMediatedSuprAd : NSObject<GADMediatedUnifiedNativeAd>

- (instancetype _Nullable )initWithTKSuprAd:(nonnull TKAdSuprAd *)suprAd withAdPlace:(NSString *)adPlace withAdSize:(CGSize)preferedAdSize;

@end

NS_ASSUME_NONNULL_END
