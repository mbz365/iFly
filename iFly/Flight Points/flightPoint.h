//
//  flightPoint.h
//  FPVDemo
//
//  Created by Mike Buzzard on 3/6/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//
//  Interface for flightPoint objects
//      - Flight Points will hold all the necessary data
//        for each point in the flight path. Ultimately the
//        data from these points will be sent to the server
//        and used to recreate Users' flight paths. This will
//        extended to contain information such as yaw, pitch,
//        and roll as well as gimbal positioning information.
//

@interface flightPoint:NSObject {
}

@property(nonatomic, readwrite) double altitude;
@property(nonatomic, readwrite) double speedX;
@property(nonatomic, readwrite) double speedY;
@property(nonatomic, readwrite) double latitude;
@property(nonatomic, readwrite) double longitude;
@property(nonatomic, readwrite) double heading;
@property(nonatomic, readwrite) int flightPointID;

@end

NS_ASSUME_NONNULL_END
