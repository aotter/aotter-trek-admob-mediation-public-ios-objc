//
//  TrekGADCustomEventNativeAd.m
//  GoogleMediation
//
//  Created by JustinTsou on 2020/12/11.
//

#import "AotterTrekGADCustomEventNativeAd.h"
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

static NSString *const customEventErrorDomain = @"com.aotter.AotterTrek.GADCustomEvent";


@interface AotterTrekGADCustomEventNativeAd() {
    NSString *_adType;
    NSString *_adPlace;
    NSError *_jsonError;
    NSString *_errorDescription;
    NSDictionary *_jsonDic;
    TKAdSuprAd *_suprAd;
    TKAdNative *_adNatve;
    NSMutableDictionary *_requeatMeta;
}

@property NSString *contentTitle;
@property NSString *contentUrl;
@end

@implementation AotterTrekGADCustomEventNativeAd

@synthesize delegate;

- (void)requestNativeAdWithParameter:(NSString *)serverParameter request:(GADCustomEventRequest *)request adTypes:(NSArray *)adTypes options:(NSArray *)options rootViewController:(UIViewController *)rootViewController {
    
    NSString *category = @"";
    if ([[request.additionalParameters allKeys]containsObject:@"category"]) {
        category = request.additionalParameters[@"category"];
    }
    if([[request.additionalParameters allKeys] containsObject:@"contentTitle"]){
        NSString *_title = request.additionalParameters[@"contentTitle"];
        if([_title isKindOfClass:[NSString class]]){
            self.contentTitle = _title;
        }
    }
    if([[request.additionalParameters allKeys] containsObject:@"contentUrl"]){
        NSString *_url = request.additionalParameters[@"contentUrl"];
        if([_url isKindOfClass:[NSString class]]){
            self.contentUrl = _url;
        }
    }
    
    // update sdk need to update mediationVersion and mediationVersionCode
    _requeatMeta = [[NSMutableDictionary alloc]initWithDictionary:@{@"mediationVersionCode":[AotterTrekAdmobUtils admobMediationVersionCode], @"mediationVersion": [AotterTrekAdmobUtils admobMediationVersionName]}];

    
    // Parse serverParameter
    
    if (serverParameter != nil && ![serverParameter isEqual: @""]) {
        NSData *data = [serverParameter dataUsingEncoding:NSUTF8StringEncoding];
        _jsonDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
    }else {
        _errorDescription = @"You must add AotterTrek adType in Google AdMob CustomEvent protal.";
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : _errorDescription,
                                   NSLocalizedFailureReasonErrorKey : _errorDescription};
        
        NSError *error = [NSError errorWithDomain:customEventErrorDomain
                                             code:0
                                         userInfo:userInfo];
        
        [self.delegate customEventNativeAd:self didFailToLoadWithError:error];
        return;
    }
    
    NSLog(@"[AotterTrek-iOS-SDK: admob mediation] CustomEvent serverParameter: %@", _jsonDic);
    
    if ([[_jsonDic allKeys] containsObject:@"adType"] && [[_jsonDic allKeys] containsObject:@"adPlace"] ) {
        _adType = [_jsonDic objectForKey:@"adType"];
        _adPlace = [_jsonDic objectForKey:@"adPlace"];
        
        if ([_adType isEqualToString:@"nativeAd"]) {
            NSLog(@"[AotterTrek-iOS-SDK: admob mediation] CustomEvent get Type == nativeAd");
            [self fetchTKAdNativeWithAdPlace:_adPlace category:category];
        }else if ([_adType isEqualToString:@"suprAd"]) {
            NSLog(@"[AotterTrek-iOS-SDK: admob mediation] CustomEvent get Type == suprAd");
            [self fetchTKSuprAdWithAdPlace:_adPlace category:category WithRootViewController:rootViewController];
        }
    }
    else if ([[_jsonDic allKeys] containsObject:@"placeUid"] ) {
        NSLog(@"[AotterTrek-iOS-SDK: admob mediation] CustomEvent get placeUid but which is not supported");
        
        self->_errorDescription = @"Invalid server parameter. placeUid is not supported now.";
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : self->_errorDescription, NSLocalizedFailureReasonErrorKey : self->_errorDescription};
        NSError *err = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
        [self.delegate customEventNativeAd:self didFailToLoadWithError:err];

        
        //WIP: waiting for update of AotterTrek-iOS-SDK for new placeUid
        /*
        _adPlace = [_jsonDic objectForKey:@"placeUid"];
        */
    }
    else{
        NSLog(@"[AotterTrek-iOS-SDK: admob mediation] CustomEvent server paramter parsing error: %@", serverParameter);
        
        self->_errorDescription = @"Invalid server parameter.";
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : self->_errorDescription, NSLocalizedFailureReasonErrorKey : self->_errorDescription};
        NSError *err = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
        [self.delegate customEventNativeAd:self didFailToLoadWithError:err];
    }
}

- (BOOL)handlesUserClicks {
    return YES;
}


- (BOOL)handlesUserImpressions {
    return YES;
}

#pragma mark - Life cycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Method

- (void)fetchTKAdNativeWithAdPlace:(NSString *)adPlace category:(NSString *)category {
    
    if (_adNatve != nil) {
        [_adNatve destroy];
    }
    
    _adNatve = [[TKAdNative alloc] initWithPlace:_adPlace category:category];
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
            
            [self.delegate customEventNativeAd:self didFailToLoadWithError:err];
        }
        else{
            NSLog(@"[AotterTrek-iOS-SDK: adMob mediation] TKAdNative fetched Ad");
            
            AotterTrekGADMediatedNativeAd *mediatedAd = [[AotterTrekGADMediatedNativeAd alloc] initWithTKNativeAd:self->_adNatve withAdPlace:adPlace];
            
            [self.delegate customEventNativeAd:self didReceiveMediatedUnifiedNativeAd:mediatedAd];
        }
    }];
}

- (void)fetchTKSuprAdWithAdPlace:(NSString *)adPlace category:(NSString *)category WithRootViewController:(UIViewController *)rootViewController {
    
    if (_suprAd != nil) {
        [_suprAd destroy];
    }
    
    _suprAd = [[TKAdSuprAd alloc] initWithPlace:adPlace category:category];
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
            
            [self.delegate customEventNativeAd:self didFailToLoadWithError:err];
        }
        else{
            
            NSLog(@"[AotterTrek-iOS-SDK: adMob mediation] TKAdSuprAd fetched Ad");
            
            AotterTrekGADMediatedSuprAd *mediatedAd = [[AotterTrekGADMediatedSuprAd alloc] initWithTKSuprAd:self->_suprAd withAdPlace:adPlace withAdSize:preferedAdSize];

            [[NSNotificationCenter defaultCenter]addObserver:self
                                                    selector:@selector(getNotification:)
                                                        name:@"SuprAdScrolled"
                                                      object:nil];
            
            [self.delegate customEventNativeAd:self didReceiveMediatedUnifiedNativeAd:mediatedAd];
        }
    }];
    
}

#pragma mark - PrivateMethod

-(void)getNotification:(NSNotification *)notification{
    if (_suprAd != nil) {
        [_suprAd notifyAdScrolled];
    }
}

@end



