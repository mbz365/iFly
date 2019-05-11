//
//  User.h
//  iFly
//
//  Created by Mike Buzzard on 3/20/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface User : NSObject

@property int userId;
@property int isLoggedIn;
@property NSString* firstName;
@property NSString* lastName;
@property NSString* username;

@end

NS_ASSUME_NONNULL_END
