//
//  AotterTrekGADCustomEventBannerAd.m
//  TestMediationBannerAd
//
//  Created by JustinTsou on 2021/5/27.
//

#import "AotterTrekGADCustomEventBannerAd.h"
#import "AotterTrekAdmobUtils.h""
#import <WebKit/WebKit.h>

#if devmode
    #import "TKAdSuprAd.h"
#else
    #import <AotterTrek-iOS-SDK/AotterTrek-iOS-SDK.h>
#endif


static NSString *const customEventErrorDomain = @"com.aotter.AotterTrek.GADCustomEvent";

@interface AotterTrekGADCustomEventBannerAd() {
    NSString *_adType;
    NSString *_adPlace;
    NSError *_jsonError;
    NSString *_errorDescription;
    NSDictionary *_jsonDic;
    TKAdSuprAd *_suprAd;
    NSMutableDictionary *_requeatMeta;
}
@property NSString *contentTitle;
@property NSString *contentUrl;
@end

@implementation AotterTrekGADCustomEventBannerAd

@synthesize delegate;

- (void)requestBannerAd:(GADAdSize)adSize parameter:(nullable NSString *)serverParameter label:(nullable NSString *)serverLabel request:(nonnull GADCustomEventRequest *)request {
    
    NSString *category = @"";
    if ([[request.additionalParameters allKeys]containsObject:@"category"]) {
        category = request.additionalParameters[@"category"];
    }
    
    // update sdk need to update mediationVersion and mediationVersionCode
    _requeatMeta = [[NSMutableDictionary alloc]initWithDictionary:@{@"mediationVersionCode":[AotterTrekAdmobUtils admobMediationVersionCode], @"mediationVersion": [AotterTrekAdmobUtils admobMediationVersion]}];
    
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
        
        [self.delegate customEventBanner:self didFailAd:error];
        return;
    }
    
    
    if ([[_jsonDic allKeys] containsObject:@"adType"] && [[_jsonDic allKeys] containsObject:@"adPlace"] ) {
        
        _adType = [_jsonDic objectForKey:@"adType"];
        _adPlace = [_jsonDic objectForKey:@"adPlace"];

        if ([_adType isEqualToString:@"suprAd"]) {
            [self fetchTKSuprAdWithAdPlace:_adPlace category:category];
        }
    }
    
}

- (void)fetchTKSuprAdWithAdPlace:(NSString *)adPlace category:(NSString *)category{
    
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
    
    [_suprAd registerPresentingViewController:[self getKeyWindow].rootViewController];
    
    [_suprAd fetchAdWithCallback:^(NSDictionary *adData, CGSize preferedAdSize, TKAdError *adError, BOOL isVideoAd, void (^loadAd)(void)) {
        
        if(adError){
            NSLog(@"[AotterTrek-iOS-SDK: adMob mediation] TKAdSuprAd fetched Ad error: %@", adError.message);
            NSString *errorDescription = adError.message;
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorDescription, NSLocalizedFailureReasonErrorKey : errorDescription};
            NSError *err = [NSError errorWithDomain:customEventErrorDomain code:0 userInfo:userInfo];
            
            [self.delegate customEventBanner:self didFailAd:err];
        }
        else{
            
            NSLog(@"[AotterTrek-iOS-SDK: adMob mediation] TKAdSuprAd fetched Ad");
            
            UIView *bannerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, preferedAdSize.width, preferedAdSize.height)];
            
            [self->_suprAd registerTKMediaView:bannerView];
            [self->_suprAd loadAd];
            
            [self.delegate customEventBanner:self didReceiveAd:bannerView];
            
        }
    }];
}


- (UIWindow *)getKeyWindow {

    NSString *deviceVersion = [UIDevice currentDevice].systemVersion;
    NSArray *firstSplit = [deviceVersion componentsSeparatedByString:@"."];
    NSString *version = [firstSplit firstObject];
    int versionNumber = [version intValue];
    
    if (versionNumber >= 13) {
        NSLog(@"Implement getKeyWindow iOS 13 above(Include)");
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            return window;
                            break;
                        }
                    }
                }
            }
        }
    }
    
    NSLog(@"Implement getKeyWindow iOS 13 below, return keyWindow from sharedApplication");
    return [UIApplication sharedApplication].keyWindow;
}

@end
