//
//  CreateFlightsViewController.m
//  iFly
//
//  Created by Mike Buzzard on 2/10/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//
//  This view controller handles the recording of flight paths
//  and allows users to upload recorded flight paths to the server
//

#import "CreateFlightsViewController.h"
#import <DJISDK/DJISDK.h>
#import <DJIWidget/DJIVideoPreviewer.h>
#import "User.h"
#import <CoreLocation/CoreLocation.h>
#import "SaveFlightViewController.h"
#import "LoggedInViewController.h"

#define WeakRef(__obj) __weak typeof(self) __obj = self
#define WeakReturn(__obj) if(__obj ==nil)return;

// Define protocols to confrom to
@interface CreateFlightsViewController ()<DJISDKManagerDelegate, DJIVideoFeedListener, DJICameraDelegate, DJIBaseProductDelegate, DJIFlightControllerDelegate, SaveFlightViewControllerDelegate, DJIGimbalDelegate>

// Outlets for UI Elements
@property (weak, nonatomic) IBOutlet UIView *fpvPreviewView;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *vSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *modeLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *stopRecordingButton;
@property (weak, nonatomic) IBOutlet UILabel *fpCount;
@property (weak, nonatomic) IBOutlet UILabel *recordStatus;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentRecordTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UILabel *recordLabel;
@property (strong, nonatomic) NSMutableDictionary *flightPoints;

@property int flightPointID;   // Store ID # of flight points
@property bool recording;      // Boolean for whether flight path is recording
@property bool isRecording;    // Boolean for whether video is recording
@property int recordIterator;  // Iterator for recording points
@property DJIGimbalAttitude gimbalAttitude; // Stores gimbal attitude

// IBAction Outlets for user interaction
- (IBAction)homeButtonPressed:(id)sender;
- (IBAction)captureAction:(id)sender;
- (IBAction)changeWorkModeAction:(id)sender;
- (IBAction)recordAction:(id)sender;
- (IBAction)saveBtnAction:(id)sender;
- (IBAction)uploadBtnAction:(id)sender;

// xib View Controllers
@property (nonatomic, strong)SaveFlightViewController *saveFlightVC;

@end

// Implementation of CreateFlightViewController
@implementation CreateFlightsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerApp];              // Register iFly with DJI
    [self setupFPV];                 // Set up the view for video feedback
    [self initUI];                   // Set up UI elements
    self.recordIterator = 10;        // Initalize record iterator count
    _flightPointID = 0;              // Init flight point ID#
    _recording = NO;                 // Init recording status
    _flightPoints = [[NSMutableDictionary alloc]init]; // Dictionary to hold all points
}


// Reestablish connection when view appears
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Initialize connection to the drone
    [DJISDKManager startConnectionToProduct];
    
    // Establish/Reestablish connection to flight controller
    DJIFlightController *flightController = [self fetchFlightController];
    [[DJISDKManager product].gimbal setDelegate:self];  // Set delegates
    [flightController setDelegate:self];
    // Reestablish connection to camera
    DJICamera *camera = [self fetchCamera];
    [camera setDelegate:self];
    
    // Set username if user is set
    if (self.currentUser.userId)
        _usernameLabel.text = self.currentUser.username;
}

// Reset connections when view disappears
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Reset camera connection
    DJICamera *camera = [self fetchCamera];
    if (camera && camera.delegate == self) {
        [camera setDelegate:nil];
    }
    
    // Reset connection to flight controller
    DJIFlightController *flightController = [self fetchFlightController];
    if (flightController && flightController.delegate == self) {
        [flightController setDelegate:nil];
    }
    
    // Reset video previewer
    [self resetVideoPreview];
}

// Enables recording of flight path
- (IBAction)recordButtonPressed:(id)sender {
    _recording = YES;
    _recordStatus.enabled = YES;
}

// Disables recording of flight path
- (IBAction)stopRecordButtonPressed:(id)sender {
    _recording = NO;
    _recordStatus.enabled = NO;
}

// Function for the action taken when record button is pressed
- (IBAction)recordAction:(id)sender {
    DJICamera* camera = [self fetchCamera];
    if (camera) {
        WeakRef(target);
        // If a path is currently recording, set it to not record
        if (self.isRecording) {
            _recording = NO;
            _recordStatus.enabled = NO;
            _recordLabel.textColor = [UIColor whiteColor];
            _recordLabel.text = @"Record";
            [camera stopRecordVideoWithCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [target showAlertViewWithTitle:@"Stop Record Video Error" withMessage:error.description];
                }
            }];
        // If a path is not currently recording, set it to record
        }else
        {
            _recording = YES;
            _recordStatus.enabled = YES;
            _uploadButton.alpha = 1;
            _recordLabel.textColor = [UIColor redColor];
            _recordLabel.text = @"Stop";
            [camera startRecordVideoWithCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [target showAlertViewWithTitle:@"Start Record Video Error" withMessage:error.description];
                }
            }];
        }
    }
}

// Display the save flight nib
- (IBAction)saveBtnAction:(id)sender {
    
    WeakRef(weakSelf);
    
    // Perform animation and display the view
    [UIView animateWithDuration:0.25 animations:^{
        WeakReturn(weakSelf);
        weakSelf.saveFlightVC.view.alpha = 1.0;
    }];
}

// Update gimbal state
- (void)gimbal:(DJIGimbal *_Nonnull)gimbal didUpdateState:(DJIGimbalState *_Nonnull)state
{
    self.gimbalAttitude = [state attitudeInDegrees];
    
}

// Delegate function to perform action on flight controller state change.
// This function is called 10 times a second and is useful for accessing
// information in the flight controller (aircraft location, etc) via the
// DJIFlightControllerState object
- (void)flightController:(DJIFlightController *_Nonnull)fc
          didUpdateState:(DJIFlightControllerState *_Nonnull)state
{
    // Create numbers for UI readout
    CLLocation *myCurrentLocation = state.aircraftLocation;
    NSNumber *latitude = [NSNumber numberWithDouble:myCurrentLocation.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:myCurrentLocation.coordinate.longitude];
    NSNumber *speed = [NSNumber numberWithDouble:
                       (sqrtf(state.velocityX*state.velocityX + state.velocityY*state.velocityY))];
    NSNumber *vSpeed = [NSNumber numberWithDouble:state.velocityZ];
    NSNumber *heading = [NSNumber numberWithDouble:fc.compass.heading];
    NSNumber *altitude = [NSNumber numberWithDouble:state.altitude];
    NSNumber *gimbalPitch = [NSNumber numberWithFloat:(_gimbalAttitude.pitch)];
    
    // Construct flightPoint if user is recording and recordIterator has reached desired value
    if ((_recording) && (_recordIterator == 10)) {
        // reset iterator
        _recordIterator = 1;
        // record point
        NSDictionary *currentPoint = @{ @"altitude" : altitude,
                                        @"latitude" : latitude,
                                        @"longitude" : longitude,
                                        @"speedY" : vSpeed,
                                        @"speedX" : speed,
                                        @"heading": heading,
                                        @"gimbalPitch": gimbalPitch
                                        };
        
        // conversion of point number to be stored in dictionary
        NSNumber *fpID = [NSNumber numberWithInt:_flightPointID];
        // Add current flightPoint to flightPoints dictionary
        [_flightPoints setObject: currentPoint forKey:[fpID stringValue]];
        // Increment flight point #
        _flightPointID += 1;
        // Update label
        _fpCount.text = [fpID stringValue];
    }
    // Record every 1 second
    else if ((_recording) && (_recordIterator < 10)) {
        _recordIterator += 1;
    }
    // Stop recording when max points reached
    if (_flightPointID == 99) {
        _recording = false;
    }
    
    
    // Populate UI Labels
    self.modeLabel.text = state.flightModeString;
    self.gpsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)state.satelliteCount];
    self.vSpeedLabel.text = [NSString stringWithFormat:@"%0.1f Mph",(state.velocityZ * 2.23694)];
    self.speedLabel.text = [NSString stringWithFormat:@"%0.1f Mph",((sqrtf(state.velocityX*state.velocityX + state.velocityY*state.velocityY))*2.23694)];
    self.altitudeLabel.text = [NSString stringWithFormat:@"%0.1f Ft",(state.altitude * 3.28084)];
    
}

// Saves dictionary of recorded flight points to a plist/JSON file
- (void)saveDictionary {
    
    // Currently writing both JSON and plist files to test
    
    // Retrieve path to JSON file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"flightPoints.json"];
    
    // Create the file if it doenst exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
    
    NSError *error;
    
    // Serialize flightPoints dictionary and write into file
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: _flightPoints options:(NSJSONWritingPrettyPrinted) error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [jsonString writeToFile:path atomically:YES];
    
    NSDictionary *flightToWrite = [NSDictionary dictionaryWithDictionary:_flightPoints];
    
    // Write plist file
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths firstObject];
    path = [documentsDirectory stringByAppendingPathComponent:@"flightPoints.plist"];
    
    // Create plist if it doesnt exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
    
    NSLog(@"%@", path);
    bool wrotePlist = [flightToWrite writeToFile:path atomically:YES];
    if (wrotePlist) {
        NSLog(@"wrote plist file");
    }
    else NSLog(@"invalid plist file");
    
}

// Uploads flight information to the web service to be stored on the server
- (IBAction)uploadBtnAction:(id)sender {
    
    // Retrieve dictionary of flight info
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"flightPoints.plist"];
    NSDictionary *flightData = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: flightData options:(NSJSONWritingPrettyPrinted) error:&error];
    
    // Submit dictionary to web service
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: [NSString stringWithFormat:@"https://afternoon-thicket-42652.herokuapp.com/uploadFlight.php"]]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:jsonData];
    
    NSURLResponse *response;
    NSData *responseData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", responseString);
    
}

// Sends the flight information and point information to the server to be stored
- (void)uploadFlight {
    // Retrieve dictionary of flight info
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"flightPoints.plist"];
    NSDictionary *flightData = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: flightData options:(NSJSONWritingPrettyPrinted) error:&error];
    
    // Submit dictionary to web service
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: [NSString stringWithFormat:@"https://afternoon-thicket-42652.herokuapp.com/uploadFlight.php"]]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:jsonData];
    
    // Echo response for debugging
    NSURLResponse *response;
    NSData *responseData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", responseString);
}

// Delegate Functions for SaveFlightViewController

// Dismisses the view controller
-(void)cancelBtnActionInSaveFlightViewController:(SaveFlightViewController *)waypointConfigVC
{
    WeakRef(weakSelf);
    
    [UIView animateWithDuration:0.25 animations:^{
        WeakReturn(weakSelf);
        weakSelf.saveFlightVC.view.alpha = 0;
    }];
}

// Action to take when save button is pressed
-(void)saveBtnActionInSaveFlightViewController:(SaveFlightViewController *)saveFlightVC
{
    WeakRef(weakSelf);
    
    // Animate view controller
    [UIView animateWithDuration:0.25 animations:^{
        WeakReturn(weakSelf);
        weakSelf.saveFlightVC.view.alpha = 0; // set view to initially be invisible
    }];
    
    // Currently writing both JSON and plist files
    
    // Retrieve path to JSON file in app documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"flightPoints.json"];
    
    // Create the file if it doenst exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
    
    NSError *error;
    
    // Create flights dictionary with entered information
    
    NSNumber *userId = [NSNumber numberWithInteger:self.currentUser.userId];
    NSDictionary *flights = @{ @"name" : saveFlightVC.nameTextField.text, @"description": saveFlightVC.descTextField.text, @"user" : userId, @"points": _flightPoints, @"location": saveFlightVC.locationTextField.text};
    
    // Serialize flightPoints dictionary and write into file
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: flights options:(NSJSONWritingPrettyPrinted) error:&error];
    
    // Encode json string
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // Write json file to path
    [jsonString writeToFile:path atomically:YES];
    
    // Write plist file
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths firstObject];
    path = [documentsDirectory stringByAppendingPathComponent:@"flightPoints.plist"];
    
    // Create plist if it doesnt exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
    // Write file to path
    NSLog(@"%@", path);
    bool wrotePlist = [flights writeToFile:path atomically:YES];
    if (wrotePlist) {
        NSLog(@"wrote plist file");
    }
    else NSLog(@"invalid plist file");
    
    [self uploadFlight];
    
}

// Set up the UI
-(void)initUI{
    
    // Create instance of SaveFlightViewController and set to be invisible
    self.saveFlightVC = [[SaveFlightViewController alloc] initWithNibName:@"SaveFlightViewController" bundle:[NSBundle mainBundle]];
    self.saveFlightVC.view.alpha = 0;
    
    // Set up the size of the view controller
    self.saveFlightVC.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    // Set the x and y origins of the view controller
    CGFloat configVCOriginX = (CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.saveFlightVC.view.frame))/2;
    CGFloat configVCOriginY = 8;
    
    // Define the view frame
    [self.saveFlightVC.view setFrame:CGRectMake(configVCOriginX, configVCOriginY, CGRectGetWidth(self.saveFlightVC.view.frame), CGRectGetHeight(self.saveFlightVC.view.frame))];
   
    // Set the delegate
    self.saveFlightVC.delegate = self;
    
    // Add the view to the current vc
    [self.view addSubview:self.saveFlightVC.view];
}

// set the necessary variables in the save flight view controller
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LoggedInViewController *vc = [segue destinationViewController];
    vc.currentUser = self.currentUser;
}

// Generic function for displaying an alert
- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

// Setup the video previewer and check if aircraft is a dual feed model
- (void)setupFPV {
    [[DJIVideoPreviewer instance] setView:self.fpvPreviewView];
    DJIBaseProduct *product = [DJISDKManager product];
    
    // Check for dual video feed models
    if ([product.model isEqual:DJIAircraftModelNameA3] ||
        [product.model isEqual:DJIAircraftModelNameN3] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600Pro]){
        [[DJISDKManager videoFeeder].secondaryVideoFeed addListener:self withQueue:nil];
        
        // Initiate single video feed
    }else{
        [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
    }
    [[DJIVideoPreviewer instance] start];
}

// Reset video previewer to avoid issues when the connection changes
- (void)resetVideoPreview {
    [[DJIVideoPreviewer instance] unSetView];
    DJIBaseProduct *product = [DJISDKManager product];
    if ([product.model isEqual:DJIAircraftModelNameA3] ||
        [product.model isEqual:DJIAircraftModelNameN3] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600Pro]){
        [[DJISDKManager videoFeeder].secondaryVideoFeed removeListener:self];
    }else{
        [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];
    }
}

// Retrieve DJI Camera type
- (DJICamera*) fetchCamera {
    // Check if valid DJI product
    if (![DJISDKManager product]) {
        return nil;
    }
    
    // Check if product is a handheld or aircraft, return camera
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).camera;
    }else if ([[DJISDKManager product] isKindOfClass:[DJIHandheld class]]){
        return ((DJIHandheld *)[DJISDKManager product]).camera;
    }
    
    return nil;
}

// Retrieve the DJI Flight Controller
- (DJIFlightController*) fetchFlightController {
    
    // Check if valid DJI product
    if (![DJISDKManager product]) {
        return nil;
    }
    
    // Check if product is a handheld or aircraft, return flightController
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
        // If handheld, return nil
    }else if ([[DJISDKManager product] isKindOfClass:[DJIHandheld class]]){
        return nil;
    }
    
    return nil;
}

// Register App with DJI
- (void)registerApp
{
    [DJISDKManager registerAppWithDelegate:self];
}

// Display success or error message depending on activation result
- (void)appRegisteredWithError:(NSError *)error
{
    // Set value of message based on activation status
    NSString* message = @"App was succesfully registered with DJI";
    if (error) {
        message = @"App registration failed";
    }else
    {
        NSLog(@"App successfully registered");
    }
    
    // Display message
    // [self showAlertViewWithTitle:@"App Registration" withMessage:message];
    
    // Initiate connection to the drone
    [DJISDKManager startConnectionToProduct];
}

// When product is connected, set up necessary delegates
- (void)productConnected:(DJIBaseProduct *)product
{
    // Uncomment for debugging
    // [self showAlertViewWithTitle:@"productConnected" withMessage:@""];
    
    if(product){
        // Set camera delegate
        DJICamera *camera = [self fetchCamera];
        if (camera != nil) {
            camera.delegate = self;
        }
        
        // Set flight controller delegate
        DJIFlightController *flightController = [self fetchFlightController];
        if (flightController != nil) {
            flightController.delegate = self;
        }
        
        [self setupFPV];
        
    }
    
    // Uncomment for debugging product connection
    //[self showAlertViewWithTitle:@"Product Connected" withMessage:@""];
    
}

// Reset the video preview & delegates when the drone is disconnected
- (void)productDisconnected
{
    
    DJICamera *camera = [self fetchCamera];
    if (camera && camera.delegate == self) {
        [camera setDelegate:nil];
    }
    
    DJIFlightController *flightController = [self fetchFlightController];
    if (flightController && flightController.delegate == self) {
        [flightController setDelegate:nil];
    }
    
    [self resetVideoPreview];
    [self showAlertViewWithTitle:@"Product Disconnected" withMessage:@""];
    
}

// Will constantly receive video streaming data and update the view
-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData {
    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
}

// Delegate function to perform action on camera state change
-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState
{
    // Update the current state of the camera
    self.isRecording = systemState.isRecording;
    // Update the record time label to be hidden or displayed
    [self.currentRecordTimeLabel setHidden:!self.isRecording];
    // Set the record time label to the proper time
    [self.currentRecordTimeLabel setText:[self formattingSeconds:systemState.currentVideoRecordingTimeInSeconds]];
    
}

// Method formats a number of seconds and returns it as a string
- (NSString *)formattingSeconds:(int)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSString *formattedTimeString = [formatter stringFromDate:date];
    return formattedTimeString;
}

// Go home segue
- (IBAction)homeButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"goHome" sender:self];
}

// Capture action for camera button
- (IBAction)captureAction:(id)sender {
    
    DJICamera* camera = [self fetchCamera];
    if (camera) {
        WeakRef(target);
        [camera setShootPhotoMode:DJICameraShootPhotoModeSingle withCompletion:^(NSError * _Nullable error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [camera startShootPhotoWithCompletion:^(NSError * _Nullable error) {
                    WeakReturn(target);
                    if (error) {
                        [target showAlertViewWithTitle:@"Camera Error" withMessage:error.description];
                    }
                }];
            });
        }];
    }
}

// Change the working mode of the camera using the segmented control
// (exists in case photograpy is implemented later)
- (IBAction)changeWorkModeAction:(id)sender {
    
    UISegmentedControl *segmentControl = (UISegmentedControl *)sender;
    DJICamera* camera = [self fetchCamera];
    
    if (camera) {
        WeakRef(target);
        if (segmentControl.selectedSegmentIndex == 0) { //Take photo
            
            [camera setMode:DJICameraModeShootPhoto withCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [target showAlertViewWithTitle:@"Could not change camera mode" withMessage:error.description];
                }
            }];
            
        }else if (segmentControl.selectedSegmentIndex == 1){ //Record video
            
            [camera setMode:DJICameraModeRecordVideo withCompletion:^(NSError * _Nullable error) {
                WeakReturn(target);
                if (error) {
                    [target showAlertViewWithTitle:@"Could not change camera mode" withMessage:error.description];
                }
            }];
            
        }
    }
    
}

@end
