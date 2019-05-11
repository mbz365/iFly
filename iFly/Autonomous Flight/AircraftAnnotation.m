//
//  AircraftAnnotation.m
//  iFly
//
//  Created by Mike Buzzard on 3/16/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import "AircraftAnnotation.h"

@implementation AircraftAnnotation

// build the location coordinate
-(id) initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    if (self) {
        _coordinate = coordinate;
    }
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coordinate = newCoordinate;
}

-(void)updateHeading:(float)heading
{
    if (self.annotationView) {
        [self.annotationView updateHeading:heading];
    }
}
@end
