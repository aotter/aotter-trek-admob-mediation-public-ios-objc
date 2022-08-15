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
#import "AotterTrekAdmobUtils.h"
#import <GoogleMobileAds/Mediation/GADMediationAdapter.h>


#if devmode
    #import "TKAdSuprAd.h"
    #import "TKAdNative.h"
#else
    #import <AotterTrek-iOS-SDK/AotterTrek-iOS-SDK.h>
#endif

#define ATOMIC_FLAG_INIT { 0 }

static NSString *const customEventErrorDomain = @"com.aotter.AotterTrek.GADCustomEvent";

@interface AotterTrekGADMediaAdapter()<GADMediationNativeAd> {
    TKAdSuprAd *_suprAd;
    TKAdNative *_adNatve;
    NSError *_jsonError;
    NSString *_errorDescription;
    NSMutableDictionary *_requeatMeta;
    
    GADMediationNativeLoadCompletionHandler _loadCompletionHandler;
    __weak id<GADMediationNativeAdEventDelegate> _deletage;
}
@property NSString *adType;
@property NSString *contentTitle;
@property NSString *contentUrl;
@property NSString *category;
@property NSString *clientId;
@property NSString *placeUid;
@end


@implementation AotterTrekGADMediaAdapter

+ (GADVersionNumber)adSDKVersion {
    //TODO: get version string from AotterTrek SDK
    NSString *versionString = @"1.0.0";
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
    //TODO: get version string from this admob statics
    NSString *versionString = @"1.0.0";
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
    return [GADCustomEventExtras class];
}



-(void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler{
    //TODO: refactor with singleton version handler
    _requeatMeta = [[NSMutableDictionary alloc]initWithDictionary:@{@"mediationVersionCode":[NSNumber numberWithInt:1],@"mediationVersion":@"AdMob_1.0.6"}];
    
    NSLog(@"[AotterTrekGADCustomEventNativeAd] loadNativeAdForAdConfiguration");
    
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
    
    
    
    //try extract clientId & placeUid from credentials.settings
    @try {
        NSString *serverParameter = adConfiguration.credentials.settings[@"parameter"];
        NSData *data = [serverParameter dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if([parameters.allKeys containsObject:@"clientId"]){
            self.clientId = parameters[@"clientId"];
        }
        
        if([parameters.allKeys containsObject:@"placeUid"]){
            self.placeUid = parameters[@"placeUid"];
        }
        
        if([parameters.allKeys containsObject:@"adType"]){
            self.adType = parameters[@"adType"];
        }
    } @catch (NSException *exception) {
        NSLog(@"[AotterTrekGADCustomEventNativeAd] extract info from adConfiguration.credentials.settings failed. exception: %@", exception.description);
    } @finally{
        NSLog(@"[AotterTrekGADCustomEventNativeAd] extracted clientId: %@, placeUid: %@, adType: %@", self.clientId, self.placeUid, self.adType);
    }
    
    
    if([self.placeUid length] == 0){
        return;
    }
        
    
    //try extract extras from CustomEventExtras
    @try {
        GADCustomEventExtras *extras = adConfiguration.extras;
        NSDictionary *myExtras = [extras extrasForLabel:@"AotterTrekGADCustomEventNativeAd"];
        if([myExtras.allKeys containsObject:@"category"]){
            self.category = myExtras[@"category"];
        }
        if([myExtras.allKeys containsObject:@"contentTitle"]){
            self.contentTitle = myExtras[@"contentTitle"];
        }
        if([myExtras.allKeys containsObject:@"contentUrl"]){
            self.contentUrl = myExtras[@"contentUrl"];
        }
    } @catch (NSException *exception) {
        NSLog(@"[AotterTrekGADCustomEventNativeAd] extract info from adConfiguration.extras failed. exception: %@", exception.description);
    } @finally{
        NSLog(@"[AotterTrekGADCustomEventNativeAd] extracted category: %@, contentTitle: %@, contentUrl: %@", self.category, self.contentTitle, self.contentUrl);
    }
    
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

- (void)fetchTKAdNative{
    if (_adNatve != nil) {
        [_adNatve destroy];
    }
    
    
    _adNatve = [[TKAdNative alloc] initWithPlace:self.placeUid category:self.category];
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
            NSLog(@"[AotterTrek-iOS-SDK: adMob mediation] TKAdNative fetched Ad error: %@", adError.message);
           
            self->_errorDescription = adError.message;
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : self->_errorDescription, NSLocalizedFailureReasonErrorKey : self->_errorDescription};
            NSError *err = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
            
            _deletage = _loadCompletionHandler(nil, err);
        }
        else{
            NSLog(@"[AotterTrek-iOS-SDK: adMob mediation] TKAdNative fetched Ad");
            
            AotterTrekGADMediatedNativeAd *mediatedAd = [[AotterTrekGADMediatedNativeAd alloc] initWithTKNativeAd:self->_adNatve withAdPlace:self.placeUid];
            _deletage = _loadCompletionHandler(mediatedAd, nil);
        }
    }];
}

- (void)fetchTKSuprAdWithRootViewController:(UIViewController *)rootViewController {
    
    if (_suprAd != nil) {
        [_suprAd destroy];
    }
    
    _suprAd = [[TKAdSuprAd alloc] initWithPlace:self.placeUid category:self.category];
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
            NSLog(@"[AotterTrek-iOS-SDK: adMob mediation] TKAdSuprAd fetched Ad error: %@", adError.message);
            NSString *errorDescription = adError.message;
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorDescription, NSLocalizedFailureReasonErrorKey : errorDescription};
            NSError *err = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
            
            _deletage = _loadCompletionHandler(nil, err);
        }
        else{
            
            NSLog(@"[AotterTrek-iOS-SDK: adMob mediation] TKAdSuprAd fetched Ad");
            
            AotterTrekGADMediatedSuprAd *mediatedAd = [[AotterTrekGADMediatedSuprAd alloc] initWithTKSuprAd:self->_suprAd withAdPlace:self.placeUid withAdSize:preferedAdSize];

            [[NSNotificationCenter defaultCenter]addObserver:self
                                                    selector:@selector(getNotification:)
                                                        name:@"SuprAdScrolled"
                                                      object:nil];
            
            _deletage = _loadCompletionHandler(mediatedAd, nil);
        }
    }];
    
}


-(void)getNotification:(NSNotification *)notification{
    if (_suprAd != nil) {
        [_suprAd notifyAdScrolled];
    }
}

@end
