//
//  AotterTrekAdmobUtils.m
//  AotterServiceTest
//
//  Created by Aotter superwave on 2022/6/6.
//  Copyright © 2022 Aotter. All rights reserved.
//

#import "AotterTrekAdmobUtils.h"

#define staticAdmobMediationVersionCode @2
#define staticAdmobMediationVersion @"AdMob_1.0.7"

@implementation AotterTrekAdmobUtils
+ (NSNumber *)admobMediationVersionCode{
    if(staticAdmobMediationVersionCode && staticAdmobMediationVersionCode > 0){
        return staticAdmobMediationVersionCode;
    }
    
    return @0;
}

+ (NSString *)admobMediationVersion{
    if (staticAdmobMediationVersion){
        return staticAdmobMediationVersion;
    }
    
    return @"AdMob_unknown";
}
@end
