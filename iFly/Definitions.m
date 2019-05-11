//
//  DemoUtility.m
//  iFly
//
//  Created by Mike Buzzard on 3/18/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import "Definitions.h"
#import <DJISDK/DJISDK.h>

inline void ShowMessage(NSString *title, NSString *message, id target, NSString *cancleBtnTitle)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:target cancelButtonTitle:cancleBtnTitle otherButtonTitles:nil];
        [alert show];
    });
}
