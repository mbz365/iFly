//
//  MapController.h
//  iFly
//
//  Created by Mike Buzzard on 3/16/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AircraftAnnotation.h"

@interface MapController : NSObject

@property (strong, nonatomic) NSMutableArray *editPoints; // Array of Waypoints
@property (nonatomic, strong) AircraftAnnotation* aircraftAnnotation; // Aircraft object

- (void)addPoint:(CGPoint)point withMapView:(MKMapView *)mapView; // Adds a point to the map view
- (void)cleanAllPointsWithMapView:(MKMapView *)mapView;           // Clears added points
- (NSArray *)wayPoints;                                           // Waypoint Array

// Methods for providing visual feedback of aircraft location
-(void)updateAircraftLocation:(CLLocationCoordinate2D)location withMapView:(MKMapView *)mapView;
-(void)updateAircraftHeading:(float)heading;

@end
