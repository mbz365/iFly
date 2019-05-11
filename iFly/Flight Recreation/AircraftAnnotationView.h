//
//  AircraftAnnotationView.h
//  iFly
//
//  Created by Mike Buzzard on 3/16/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface AircraftAnnotationView : MKAnnotationView

-(void) updateHeading:(float)heading;

@end
