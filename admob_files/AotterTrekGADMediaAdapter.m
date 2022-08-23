//
//  AotterTrekGADMediaAdapter.m
//  AotterServiceTest
//
//  Created by Aotter superwave on 2022/8/15.
//  Copyright © 2022 Aotter. All rights reserved.
//

#import "AotterTrekGADMediaAdapter.h"
#include <stdatomic.h>
#import "AotterTrekGADMediatedNativeAd.h"
#import "AotterTrekGADMediatedSuprAd.h"
#import "AotterTrekGADMediatedBannerAd.h"
#import "AotterTrekAdmobUtils.h"
#import <GoogleMobileAds/Mediation/GADMediationAdapter.h>


#if devmode
    #import "TKAdSuprAd.h"
    #import "TKAdNative.h"
    #import "AotterTrek.h"
#else
    #import <AotterTrek-iOS-SDK/AotterTrek-iOS-SDK.h>
#endif

#define ATOMIC_FLAG_INIT { 0 }

static NSString *const customEventErrorDomain = @"com.aotter.AotterTrek.GADCustomEvent";

@interface AotterTrekGADMediaAdapter()<GADMediationNativeAd, GADMediationBannerAd> {
    TKAdSuprAd *_suprAd;
    TKAdNative *_adNatve;
    TKAdSuprAd *_bannerAd;
    NSError *_jsonError;
    NSString *_errorDescription;
    NSMutableDictionary *_requeatMeta;
    
    GADMediationNativeLoadCompletionHandler _loadCompletionHandler;
    GADMediationBannerLoadCompletionHandler _loadCompletionHandlerBanner;
    __weak id<GADMediationNativeAdEventDelegate> _delegate;
    __weak id<GADMediationBannerAdEventDelegate> _delegateBanner;
}
@property NSString *adType;
@property NSString *adPlace;
@property NSString *contentTitle;
@property NSString *contentUrl;
@property NSString *category;
@property NSString *clientId;
//@property NSString *placeUid;
@end


@implementation AotterTrekGADMediaAdapter

+ (GADVersionNumber)adSDKVersion {
    NSString *versionString = @"1.0.0";
    
    //added since trek SDK 3.7.7
    if([AotterTrek respondsToSelector:@selector(sdkVersion)]){
        versionString = [AotterTrek sdkVersion];
    }
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count >= 3) {
      version.majorVersion = [versionComponents[0] integerValue];
      version.minorVersion = [versionComponents[1] integerValue];
      version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}

+ (GADVersionNumber)adapterVersion {
    NSString *versionString = [AotterTrekAdmobUtils admobMediationVersion];
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count >= 3) {
      version.majorVersion = [versionComponents[0] integerValue];
      version.minorVersion = [versionComponents[1] integerValue];
      version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
    //如果需要額外的 extras，可以塞在這邊
    return nil;
//    GADCustomEventExtras *extras = [[GADCustomEventExtras alloc] init];
//    return extras;
}

#pragma mark General
-(void)extractServerParamter:(NSString *)serverParameterString{
    self.clientId = @"";
    self.adPlace = @"";
    self.adType = @"";
    
    //try extract clientId & placeUid from credentials.settings
    @try {
        NSData *data = [serverParameterString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if([parameters.allKeys containsObject:@"clientId"]){
            self.clientId = parameters[@"clientId"];
        }
        
        if([parameters.allKeys containsObject:@"adPlace"]){
            self.adPlace = parameters[@"adPlace"];
        }
        
//        if([parameters.allKeys containsObject:@"placeUid"]){
//            self.placeUid = parameters[@"placeUid"];
//        }
        
        if([parameters.allKeys containsObject:@"adType"]){
            self.adType = parameters[@"adType"];
        }
    } @catch (NSException *exception) {
        NSLog(@"%@ >> extract info from adConfiguration.credentials.settings failed. exception: %@", NSStringFromClass([self class]), exception.description);
    } @finally{
        NSLog(@"%@ >> extracted clientId: %@, adPlace: %@, adType: %@", NSStringFromClass([self class]), self.clientId, self.adPlace, self.adType);
    }
}

-(void)extractExtrasFromDeveloper:(GADCustomEventExtras *)extras{
    
}

#pragma mark Load ad

-(void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler{
    NSLog(@"%@ >> loadBannerForAdConfiguration", NSStringFromClass([self class]));
    
    //1. Versioning
    NSNumber *versionCode = [AotterTrekAdmobUtils admobMediationVersionCode];
    NSString *versionName = [AotterTrekAdmobUtils admobMediationVersionName];
    _requeatMeta = [[NSMutableDictionary alloc] initWithDictionary:@{@"mediationVersionCode":versionCode,
                                                                    @"mediationVersion":versionName}];
    
    //2. completion Handler
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    _loadCompletionHandlerBanner = ^id<GADMediationBannerAdEventDelegate>(
        _Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
      // Only allow completion handler to be called once.
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }

      id<GADMediationBannerAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        // Call original handler and hold on to its return value.
        delegate = originalCompletionHandler(ad, error);
      }

      // Release reference to handler. Objects retained by the handler will also be released.
      originalCompletionHandler = nil;

      return delegate;
    };
    
    
    //3. extract server paramter
    [self extractServerParamter:adConfiguration.credentials.settings[@"parameter"]];
    if([self.adType length] == 0){
        return;
    }
    if([self.adPlace length] == 0){
        return;
    }
    

        
    //4. extract extras from developer
    [self extractExtrasFromDeveloper:adConfiguration.extras];
    
    
    //5. fetch banner
    [self fetchTKBannerAdWithRootViewController:adConfiguration.topViewController];
}


-(void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler{
    NSLog(@"%@ >> loadNativeAdForAdConfiguration", NSStringFromClass([self class]));
    
    //1. versioning
    NSNumber *versionCode = [AotterTrekAdmobUtils admobMediationVersionCode];
    NSString *versionName = [AotterTrekAdmobUtils admobMediationVersionName];
    _requeatMeta = [[NSMutableDictionary alloc] initWithDictionary:@{@"mediationVersionCode":versionCode,
                                                                    @"mediationVersion":versionName}];
    //2. completion handler
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    _loadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(
        _Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
      // Only allow completion handler to be called once.
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }

      id<GADMediationNativeAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        // Call original handler and hold on to its return value.
        delegate = originalCompletionHandler(ad, error);
      }

      // Release reference to handler. Objects retained by the handler will also be released.
      originalCompletionHandler = nil;

      return delegate;
    };
    
    
    
    //3. extract server parameters
    [self extractServerParamter:adConfiguration.credentials.settings[@"parameter"]];
    if([self.adType length] == 0){
        return;
    }
    if([self.adPlace length] == 0){
        return;
    }
    
    //4. extract extras from Deveoper
    [self extractExtrasFromDeveloper:adConfiguration.extras];
        
    
    //5. fetch ad
    if([self.adType isEqualToString:@"suprAd"]){
        [self fetchTKSuprAdWithRootViewController:adConfiguration.topViewController];
    }
    else {
        [self fetchTKAdNative];
    }
}

#pragma mark - MediatedAd Delegates

-(BOOL)handlesUserClicks{
    return YES;
}

-(BOOL)handlesUserImpressions{
    return YES;
}

#pragma mark - Trek Ad Helpers

#pragma mark Native Ad
- (void)fetchTKAdNative{
    if (_adNatve != nil) {
        [_adNatve destroy];
    }
    
    
    _adNatve = [[TKAdNative alloc] initWithPlace:self.adPlace category:self.category];
    _adNatve.requestMeta = _requeatMeta;
    if(self.contentTitle){
        if([_adNatve respondsToSelector:@selector(setAdContentTitle:)]){
            [_adNatve performSelector:@selector(setAdContentUrl:) withObject:self.contentUrl];
        }
    }
    if(self.contentUrl){
        if([_adNatve respondsToSelector:@selector(setAdContentUrl:)]){
            [_adNatve performSelector:@selector(setAdContentUrl:) withObject:self.contentUrl];
        }
    }
    
    [_adNatve fetchAdWithCallback:^(NSDictionary *adData, TKAdError *adError) {
        if(adError){
            NSLog(@"%@ >> TKAdNative fetched Ad error: %@", NSStringFromClass([self class]), adError.message);
           
            self->_errorDescription = adError.message;
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : self->_errorDescription, NSLocalizedFailureReasonErrorKey : self->_errorDescription};
            NSError *err = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
            
            _delegate = _loadCompletionHandler(nil, err);
        }
        else{
            NSLog(@"%@ >> TKAdNative fetched Ad", NSStringFromClass([self class]));
            
            AotterTrekGADMediatedNativeAd *mediatedAd = [[AotterTrekGADMediatedNativeAd alloc] initWithTKNativeAd:self->_adNatve withAdPlace:self.adPlace];
            _delegate = _loadCompletionHandler(mediatedAd, nil);
        }
    }];
}

#pragma mark SuprAd

- (void)fetchTKSuprAdWithRootViewController:(UIViewController *)rootViewController {
    
    if (_suprAd != nil) {
        [_suprAd destroy];
    }
    
    _suprAd = [[TKAdSuprAd alloc] initWithPlace:self.adPlace category:self.category];
    _suprAd.requestMeta = _requeatMeta;
    if(self.contentTitle){
        if([_suprAd respondsToSelector:@selector(setAdContentTitle:)]){
            [_suprAd performSelector:@selector(setAdContentTitle:) withObject:self.contentTitle];
        }
    }
    if(self.contentUrl){
        if([_suprAd respondsToSelector:@selector(setAdContentUrl:)]){
            [_suprAd performSelector:@selector(setAdContentUrl:) withObject:self.contentUrl];
        }
    }
    
    [_suprAd registerPresentingViewController:rootViewController];
    
    [_suprAd fetchAdWithCallback:^(NSDictionary *adData, CGSize preferedAdSize, TKAdError *adError, BOOL isVideoAd, void (^loadAd)(void)) {
        
        if(adError){
            NSLog(@"%@ >> TKAdSuprAd fetched Ad error: %@", NSStringFromClass([self class]), adError.message);
            NSString *errorDescription = adError.message;
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorDescription, NSLocalizedFailureReasonErrorKey : errorDescription};
            NSError *err = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
            
            _delegate = _loadCompletionHandler(nil, err);
        }
        else{
            
            NSLog(@"%@ >> TKAdSuprAd fetched Ad", NSStringFromClass([self class]));
            
            AotterTrekGADMediatedSuprAd *mediatedAd = [[AotterTrekGADMediatedSuprAd alloc] initWithTKSuprAd:self->_suprAd withAdPlace:self.adPlace withAdSize:preferedAdSize];

            [[NSNotificationCenter defaultCenter]addObserver:self
                                                    selector:@selector(getNotification:)
                                                        name:@"SuprAdScrolled"
                                                      object:nil];
            
            _delegate = _loadCompletionHandler(mediatedAd, nil);
        }
    }];
    
}

-(void)getNotification:(NSNotification *)notification{
    if (_suprAd != nil) {
        [_suprAd notifyAdScrolled];
    }
}

#pragma mark Banner ad
-(void)fetchTKBannerAdWithRootViewController:(UIViewController *)rootViewController{
    if(_bannerAd != nil){
        [_bannerAd destroy];
    }
    
    _bannerAd = [[TKAdSuprAd alloc] initWithPlace:self.adPlace category:self.category];
    _bannerAd.requestMeta = _requeatMeta;
    if(self.contentTitle){
        if([_bannerAd respondsToSelector:@selector(setAdContentTitle:)]){
            [_bannerAd performSelector:@selector(setAdContentTitle:) withObject:self.contentTitle];
        }
    }
    if(self.contentUrl){
        if([_bannerAd respondsToSelector:@selector(setAdContentUrl:)]){
            [_bannerAd performSelector:@selector(setAdContentUrl:) withObject:self.contentUrl];
        }
    }
    
    [_bannerAd registerPresentingViewController:rootViewController];
    
    [_bannerAd fetchAdWithCallback:^(NSDictionary *adData, CGSize preferedAdSize, TKAdError *adError, BOOL isVideoAd, void (^loadAd)(void)) {
        
        if(adError){
            NSLog(@"%@ >> TKAdSuprAd(bannerAd) fetched Ad error: %@", NSStringFromClass([self class]), adError.message);
            NSString *errorDescription = adError.message;
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorDescription, NSLocalizedFailureReasonErrorKey : errorDescription};
            NSError *err = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
            
            _delegateBanner = _loadCompletionHandlerBanner(nil, err);
        }
        else{
            
            NSLog(@"%@ >> TKAdSuprAd(bannerAd) fetched Ad", NSStringFromClass([self class]));
            AotterTrekGADMediatedBannerAd *mediatedBannerAd = [[AotterTrekGADMediatedBannerAd alloc] initWithTKSuprAd:self->_bannerAd withAdPlace:self.adPlace withAdSize:preferedAdSize];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                    selector:@selector(getNotification:)
                                                        name:@"SuprAdScrolled"
                                                      object:nil];
            
            _delegateBanner = _loadCompletionHandlerBanner(mediatedBannerAd, nil);
        }
    }];
}

@end
