//
//  DemoUtility.h
//  iFly
//
//  Created by Mike Buzzard on 3/18/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef DemoUtility_h
#define DemoUtility_h
#define WeakRef(__obj) __weak typeof(self) __obj = self
#define WeakReturn(__obj) if(__obj ==nil)return;
#define DEGREE(x) ((x)*180.0/M_PI)
#define RADIAN(x) ((x)*M_PI/180.0)
#endif

extern void ShowMessage(NSString *title, NSString *message, id target, NSString *cancleBtnTitle);

@class DJIFlightController;
@interface DemoUtility : NSObject
+(DJIFlightController*) fetchFlightController;
@end
