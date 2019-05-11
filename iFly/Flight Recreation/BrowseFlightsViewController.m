//
//  BrowseFlightsViewController
//  iFly
//
//  Created by Mike Buzzard on 3/16/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//
//  This view controller is used for the recreation of autonomous flight
//  paths. Lists of flight points are retrieved from the iFly server, and
//  a waypoint mission is built and uploaded based on these points.
//

#import "MapController.h"
#import "BrowseFlightsViewController.h"
#import <DJISDK/DJISDK.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CreateFlightsViewController.h"
#import <DJIWidget/DJIVideoPreviewer.h>
#import "LoggedInViewController.h"
#import "Definitions.h"

@interface BrowseFlightsViewController () <MKMapViewDelegate, CLLocationManagerDelegate, DJISDKManagerDelegate, DJIFlightControllerDelegate, DJICameraDelegate, DJIBaseProductDelegate>

// UI Labels in-flight information and enabling user interaction
@property(nonatomic, strong) IBOutlet UILabel* modeLabel;
@property(nonatomic, strong) IBOutlet UILabel* gpsLabel;
@property(nonatomic, strong) IBOutlet UILabel* hsLabel;
@property(nonatomic, strong) IBOutlet UILabel* vsLabel;
@property(nonatomic, strong) IBOutlet UILabel* altitudeLabel;
@property(nonatomic, strong) IBOutlet UIView* topBarView;
@property (weak, nonatomic) IBOutlet UIView *fpvPreviewView;
- (IBAction)homeButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
- (IBAction)startButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
- (IBAction)stopButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

// Location-based attributes
@property(nonatomic, assign) CLLocationCoordinate2D droneLocation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) MapController *mapController;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, assign) CLLocationCoordinate2D userLocation;

// Waypoint Mission object
@property(nonatomic, strong) DJIMutableWaypointMission* waypointMission;
@property (strong, nonatomic) DJIMissionControl *missionControl;

@end

@implementation BrowseFlightsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Initiate connection to drone
    [DJISDKManager startConnectionToProduct];
    // Retrieve flight controller and set delegate
    DJIFlightController *flightController = [self fetchFlightController];
    [flightController setDelegate:self];
    // Begin location services
    [self startUpdateLocation];
    NSLog(@"location updated");
    // If flight has been selected, load the mission
    if (_selectedFlight) {
        [self loadSelectedFlight];
    }
}

//
//  loadSelectedFlight() -
//      retrieves the flight points from the database with the currently selected
//      flight id. Parses the retrieved data and steps through the waypoints, checking
//      that they meet the minimum distance requirement, then adds turn mode based on
//      heading changes between the two waypoints
//
- (void) loadSelectedFlight {
    
    // Prepare http request for selected flight
    NSError *error;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: [NSString stringWithFormat:@"https://afternoon-thicket-42652.herokuapp.com/"]]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPMethod: @"POST"];
    NSString *post = [NSString stringWithFormat:@"mode=getPoints&flightNumber=%@",_selectedFlight];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    
    // Store the server response (flight points) in an NSArray
    NSURLResponse *response;
    NSData *responseData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSArray *flight = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
    
    NSMutableArray *waypoints = [[NSMutableArray alloc] init]; // list of waypoints
    
    // Initialize a waypoint mission
    DJIMutableWaypointMission *mission = [[DJIMutableWaypointMission alloc] init];
    bool finished = false;
    int count = 1;
    
    // Retrieve first point in the flight
    NSDictionary *initialPoint = [flight objectAtIndex:0];
    
    // Current latitude and longitude used to ensure points are far enough apart from each other
    double currentLatitude = [[initialPoint objectForKey:@"latitude"] doubleValue];
    double currentLongitude = [[initialPoint objectForKey:@"longitude"] doubleValue];
    double ipheading = [[initialPoint objectForKey:@"heading"] doubleValue];
    double ipaltitude = [[initialPoint objectForKey:@"altitude"] doubleValue];
    double ipspeed = [[initialPoint objectForKey:@"hspeed"] doubleValue];
    
    // Enter initial waypoint into waypoints array
    CLLocationCoordinate2D initCoordinate = CLLocationCoordinate2DMake(currentLatitude, currentLongitude);
    // [coordinateArray addObject: initCoordinate];
    DJIWaypoint *initWaypoint = [[DJIWaypoint alloc] initWithCoordinate:initCoordinate];
    initWaypoint.heading = ipheading;
    initWaypoint.altitude = ipaltitude;
    initWaypoint.speed = sqrt(ipspeed*ipspeed); // ensure speed is positive
    
    // Create waypoint actions to be added to initial and final waypoints
    DJIWaypointAction *record = [[DJIWaypointAction alloc]  initWithActionType:DJIWaypointActionTypeStartRecord param:0];
    DJIWaypointAction *stopRecord = [[DJIWaypointAction alloc] initWithActionType:DJIWaypointActionTypeStopRecord param:0];
    
    [initWaypoint addAction:record];    // Add start record action to first waypoint
    [waypoints addObject:initWaypoint]; // Add waypoint to waypoints array
    
    // Create array of waypoints
    for (int i = 1; i < [flight count]; i++) {
        // Retrieve point from dictionary if it exists
        NSDictionary *point = [flight objectAtIndex:i];
        
        // Extract information from point dictionary
        double latitude = [[point objectForKey:@"latitude"] doubleValue];
        double longitude = [[point objectForKey:@"longitude"] doubleValue];
        double heading = [[point objectForKey:@"heading"] doubleValue];
        double altitude = [[point objectForKey:@"altitude"] doubleValue];
        double speed = [[point objectForKey:@"hspeed"] doubleValue];
        
        // Compare distance
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        CLLocationCoordinate2D previousCoord = CLLocationCoordinate2DMake(currentLatitude, currentLongitude);
        MKMapPoint nextPoint = MKMapPointForCoordinate(coordinate);
        MKMapPoint previousPoint = MKMapPointForCoordinate(previousCoord);
        CLLocationDistance distance = MKMetersBetweenMapPoints(nextPoint, previousPoint);
        
        // If points are far enough apart, add to array and update current point
        if (distance >= 1)
        {
            if (CLLocationCoordinate2DIsValid(coordinate)) {
                CLLocation *currentCoord = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
                DJIWaypoint *waypoint = [[DJIWaypoint alloc] initWithCoordinate:coordinate];
                waypoint.heading = heading;
                waypoint.altitude = altitude;
                if (speed < 2) {
                    waypoint.speed = 2;
                }
                else {
                    waypoint.speed = sqrt(speed*speed);
                }
                [waypoints addObject:waypoint];
                currentLatitude = latitude;
                currentLongitude = longitude;
            }
        }
        else {
            finished = true;
            NSLog(@"finished");
        }
    }
    
    count = 1; // Limit each waypoint mission to 99
    int index = 0; // Keep track of index number in total waypoint array
    
    // Set turn mode
    for (int i = 0; i < ([waypoints count]-1); i++) {
        DJIWaypoint *waypoint1 = waypoints[i];
        DJIWaypoint *waypoint2 = waypoints[i + 1];
        double heading1 = waypoint1.heading;
        double heading2 = waypoint2.heading;
        double difference = heading1 - heading2;
        if ((difference > 0 && difference < 180) || (difference < -180)) {
            waypoint1.turnMode = DJIWaypointTurnCounterClockwise;
        }
        else if ((difference <= 0 && difference >= -180) || (difference >= 180)) {
            waypoint1.turnMode = DJIWaypointTurnClockwise;
        }
    }
    
    NSLog(@"set turn mode");
    
    while ((count < 100) && (index < [waypoints count]))
    {
        // Add waypoints to mission
        [mission addWaypoint:waypoints[index]];
        
        count += 1;
        index += 1;
        
    }
    // Set necessary mission parameters
    mission.headingMode = DJIWaypointMissionHeadingUsingWaypointHeading; // Set heading mode
    mission.flightPathMode = DJIWaypointMissionFlightPathNormal;         // Set flight path mode
    mission.autoFlightSpeed = 7;
    mission.maxFlightSpeed = 15;
    mission.rotateGimbalPitch = true;                                    // Enable gimbal rotation
    mission.finishedAction = DJIWaypointMissionFinishedNoAction;         // Hover on completion
    [[mission waypointAtIndex:([mission waypointCount] - 1)] addAction:stopRecord]; // End recording
    
    self.waypointMission = mission;
    
    NSLog(@"mission created");
    
    // Load mission into waypoing mission operator
    [[self missionOperator] loadMission:self.waypointMission];
    
    WeakRef(target);
    
    // Add listener for completion of mission
    [[self missionOperator] addListenerToFinished:self withQueue:dispatch_get_main_queue() andBlock:^(NSError * _Nullable error) {
        
        WeakReturn(target);
        
        if (error) {
            [target showAlertViewWithTitle:@"Mission Execution Failed" withMessage:[NSString stringWithFormat:@"%@", error.description]];
        }
        else {
            [target showAlertViewWithTitle:@"Mission Execution Finished" withMessage:nil];
        }
    }];
    
    // Upload mission to the drone itself
    [[self missionOperator] uploadMissionWithCompletion:^(NSError * _Nullable error) {
        if (error){
            NSString* uploadError = [NSString stringWithFormat:@"Mission Couldn't Be Uploaded:%@", error.description];
            ShowMessage(@"", @"Upload Mission Failed", nil, @"OK");
        }else {
            ShowMessage(@"", @"Upload Mission Finished", nil, @"OK");
        }
    }];
    
}

// Reset location services when view is dismissed
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // Stop location services
    [self.locationManager stopUpdatingLocation];
}

// Set up necessary items when view appears
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userLocation = kCLLocationCoordinate2DInvalid; // Initialize location to invalid
    self.mapController = [[MapController alloc] init];  // Return an instance of MapController class
    self.usernameLabel.text = self.currentUser.username;
}

// Update location using Apple Location services
-(void) startUpdateLocation
{
    if ([CLLocationManager locationServicesEnabled]) {
        // If location manager has not been initialized,
        // instantiate CLLocationManager
        if (self.locationManager == nil) {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self; // Set delegate
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager.distanceFilter = 0.1;
            if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [self.locationManager requestAlwaysAuthorization];
            }
            [self.locationManager startUpdatingLocation];
        }
    }else
    {
        [self showAlertViewWithTitle:@"Alert" withMessage:@"Could not initialize the location service"];
    }
}

// Set user location
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* location = [locations lastObject];
    self.userLocation = location.coordinate;
}

// Register app with DJI
- (void)registerApp
{
    [DJISDKManager registerAppWithDelegate:self];
}

// Initializes the user interface
-(void) initUI
{
    // Populate labels
    self.modeLabel.text = @"N/A";
    self.gpsLabel.text = @"0";
    self.vsLabel.text = @"0.0 MPH";
    self.hsLabel.text = @"0.0 MPH";
    self.altitudeLabel.text = @"0 Ft";
    
}

// Initializes data at start of app
-(void)initData
{
    // Populate locations with invalid data (to force update)
    self.userLocation = kCLLocationCoordinate2DInvalid;
    self.droneLocation = kCLLocationCoordinate2DInvalid;
    
    self.mapController = [[MapController alloc] init]; // Setup map controller
    
}

- (void)appRegisteredWithError:(NSError *)error
{
    if (error){
        // Uncomment for debugging
        //NSString *registerResult = [NSString stringWithFormat:@"Registration Error:%@", error.description];
        //ShowMessage(@"Registration Result", registerResult, nil, @"OK");
    }
    else{
        [DJISDKManager startConnectionToProduct];
    }
}

// Set the flight controller delegate when the drone is connected
- (void)productConnected:(DJIBaseProduct *)product
{
    if (product){
        DJIFlightController* flightController = [self fetchFlightController];
        if (flightController) {
            flightController.delegate = self;
        }
    }
}

// Delegate funtion for DJI flight controller
- (void)flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state
{
    // Fetch info from DJIFlightControllerState object and populate labels
    self.droneLocation = state.aircraftLocation.coordinate;
    self.modeLabel.text = state.flightModeString;
    self.gpsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)state.satelliteCount];
    self.vsLabel.text = [NSString stringWithFormat:@"%0.1f Mph",(state.velocityZ * 2.23694)];
    self.hsLabel.text = [NSString stringWithFormat:@"%0.1f Mph",((sqrtf(state.velocityX*state.velocityX + state.velocityY*state.velocityY)) * 2.23694)];
    self.altitudeLabel.text = [NSString stringWithFormat:@"%0.1f Ft",(state.altitude * 3.28084)];
    
    // Update the aircraft position on the map (location and heading)
    [self.mapController updateAircraftLocation:self.droneLocation withMapView:self.mapView];
    double radianYaw = RADIAN(state.attitude.yaw);
    [self.mapController updateAircraftHeading:radianYaw];
}

// Zoom to current aircraft location on map
- (void)focusMap
{
    // Check for valid drone location and center on coordinates
    if (CLLocationCoordinate2DIsValid(self.droneLocation)) {
        MKCoordinateRegion region = {0};
        region.center = self.droneLocation;
        region.span.latitudeDelta = 0.001;
        region.span.longitudeDelta = 0.001;
        
        // Zoom to set region
        [self.mapView setRegion:region animated:YES];
    }
}

// Generic function to diplay an alert passed in the message parameter
- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

// Retrieve a mission operator object to run the waypoint mission
-(DJIWaypointMissionOperator *)missionOperator {
    return [DJISDKManager missionControl].waypointMissionOperator;
}

- (IBAction)homeButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"goHome" sender:self];
}

- (IBAction)getFlightBtnAction:(id)sender {
    
}

// Action to be carried out when start button pressed
- (IBAction)startButtonAction:(id)sender {
    
    // Focus on drone location
    [self focusMap];
    
    WeakRef(target);
    
    // Add listener to indicate when mission is completed
    [[self missionOperator] addListenerToFinished:self withQueue:dispatch_get_main_queue() andBlock:^(NSError * _Nullable error) {
        
        WeakReturn(target);
        
        // Set failure message if mission does not succeed
        if (error) {
            [target showAlertViewWithTitle:@"Mission Execution Failed" withMessage:[NSString stringWithFormat:@"%@", error.description]];
        }
        // Set success message if mission completes successfully
        else {
            [target showAlertViewWithTitle:@"Mission Finished" withMessage:nil];
            self.stopButton.alpha = 0;
            self.startButton.alpha = 1;
        }
    }];
    
    [[self missionOperator] startMissionWithCompletion:^(NSError * _Nullable error) {
        if (error){
            ShowMessage(@"", @"Mission Couldn't Start", nil, @"OK");
        }else
        {
            // ShowMessage(@"", @"Mission Started", nil, @"OK");
            self.startButton.alpha = 0;
            self.stopButton.alpha = 1;
        }
    }];
}

// End mission
- (IBAction)stopButtonAction:(id)sender {
    // Hide stop button, display start button
    self.stopButton.alpha = 0;
    self.startButton.alpha = 1;
    [[self missionOperator] stopMissionWithCompletion:^(NSError * _Nullable error) {
        if (error){
            NSString* failedMessage = [NSString stringWithFormat:@"Stop Mission Failed: %@", error.description];
            // ShowMessage(@"", failedMessage, nil, @"OK");
        }else
        {
            ShowMessage(@"", @"Mission Stopped", nil, @"OK");
        }
        
    }];
}

// Pass currently logged in user to flight controller
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    LoggedInViewController *vc = [segue destinationViewController];
    vc.currentUser = self.currentUser;
}

// Fetch flight controller
- (DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    return nil;
}

// Add the annotations to the map view
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[AircraftAnnotation class]])
    {
        AircraftAnnotationView* annoView = [[AircraftAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Aircraft_Annotation"];
        ((AircraftAnnotation*)annotation).annotationView = annoView;
        return annoView;
    }
    
    return nil;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

@end
