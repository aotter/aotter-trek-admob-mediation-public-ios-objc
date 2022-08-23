//
//  AotterTrekAdmobUtils.m
//  AotterServiceTest
//
//  Created by Aotter superwave on 2022/6/6.
//  Copyright © 2022 Aotter. All rights reserved.
//

#import "AotterTrekAdmobUtils.h"

#define ADAPTERVERSIONCODE @3
#define ADAPTERVERSION @"1.0.8"


@implementation AotterTrekAdmobUtils
+ (NSNumber *)admobMediationVersionCode{
    return ADAPTERVERSIONCODE;
}

+ (NSString *)admobMediationVersionName{
    return [NSString stringWithFormat:@"AdMob_%@", ADAPTERVERSION];
}

+ (NSString *)admobMediationVersion{
    return ADAPTERVERSION;
}
@end
