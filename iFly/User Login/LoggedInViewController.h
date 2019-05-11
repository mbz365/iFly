//
//  LoggedInViewController.h
//  iFly
//
//  Created by Mike Buzzard on 4/27/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoggedInViewController : UIViewController
@property User *currentUser;
@end

NS_ASSUME_NONNULL_END
