//
//  AotterTrekAdmobUtils.m
//  AotterServiceTest
//
//  Created by Aotter superwave on 2022/6/6.
//  Copyright © 2022 Aotter. All rights reserved.
//

#import "AotterTrekAdmobUtils.h"

#define ADAPTERVERSIONCODE @6
#define ADAPTERVERSION @"1.1.0"


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
