//
//  BrowseFlightsViewController
//  iFly
//
//  Created by Mike Buzzard on 3/16/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface BrowseFlightsViewController : UIViewController
@property User *currentUser;        // Holds currently logged in user
@property NSString *selectedFlight; // Holds currently seleted flight
@end

NS_ASSUME_NONNULL_END
