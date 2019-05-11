//
//  FlightSearchViewController.m
//  iFly
//
//  Created by Mike Buzzard on 4/18/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import "FlightSearchViewController.h"
#import "BrowseFlightsViewController.h"
#import "CreateFlightsViewController.h"

@interface FlightSearchViewController ()
// Outlet attributes for UI Elements
@property (weak, nonatomic) IBOutlet UIButton *flightButton1;
@property (weak, nonatomic) IBOutlet UIButton *flightButton2;
@property (weak, nonatomic) IBOutlet UIButton *flightButton3;
@property (weak, nonatomic) IBOutlet UILabel *flightName1;
@property (weak, nonatomic) IBOutlet UILabel *flightName2;
@property (weak, nonatomic) IBOutlet UILabel *flightName3;
@property (weak, nonatomic) IBOutlet UILabel *flightDesc1;
@property (weak, nonatomic) IBOutlet UILabel *flightDesc2;
@property (weak, nonatomic) IBOutlet UILabel *flightDesc3;
@property (weak, nonatomic) IBOutlet UILabel *flightLoc1;
@property (weak, nonatomic) IBOutlet UILabel *flightLoc2;
@property (weak, nonatomic) IBOutlet UILabel *flightLoc3;
@property (weak, nonatomic) IBOutlet UIView *flightBg2;
@property (weak, nonatomic) IBOutlet UIView *flightBg1;
@property (weak, nonatomic) IBOutlet UIView *flightBg3;
@property (weak, nonatomic) NSString *flightID1;
@property (weak, nonatomic) NSString *flightID2;
@property (weak, nonatomic) NSString *flightID3;
@property (weak, nonatomic) NSString *selectedFlight;
// IBActions for button presses
- (IBAction)flightButton1Action:(id)sender;
- (IBAction)flightButton2Action:(id)sender;
- (IBAction)flightButton3Action:(id)sender;

@end

@implementation FlightSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI]; // Set up the ui
}

- (void)viewWillAppear:(BOOL)animated {
    [self populateFlights];  // Retrieve flight information
}

// Hide all UI elements initially
- (void)initUI {
    self.flightButton1.alpha = 0;
    self.flightButton2.alpha = 0;
    self.flightButton3.alpha = 0;
    self.flightName1.alpha = 0;
    self.flightName2.alpha = 0;
    self.flightName3.alpha = 0;
    self.flightDesc1.alpha = 0;
    self.flightDesc2.alpha = 0;
    self.flightDesc3.alpha = 0;
    self.flightLoc1.alpha = 0;
    self.flightLoc2.alpha = 0;
    self.flightLoc3.alpha = 0;
    self.flightBg1.alpha = 0;
    self.flightBg2.alpha = 0;
    self.flightBg3.alpha = 0;
}


#pragma mark - Navigation

// Set the selected flight and currently logged in user in the next view controller
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    BrowseFlightsViewController *vc = [segue destinationViewController];
    vc.selectedFlight = self.selectedFlight;
    vc.currentUser = self.currentUser;
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

// Prepare for segue by passing unique flight ID (Flight 1)
- (IBAction)flightButton1Action:(id)sender {
    _selectedFlight = _flightID1;
    [self performSegueWithIdentifier:@"mapViewSegue" sender:self];
}

// Prepare for segue by passing unique flight ID (Flight 2)
- (IBAction)flightButton2Action:(id)sender {
    _selectedFlight = _flightID2;
    [self performSegueWithIdentifier:@"mapViewSegue" sender:self];
}

// Prepare for segue by passing unique flight ID (Flight 3)
- (IBAction)flightButton3Action:(id)sender {
    _selectedFlight = _flightID3;
    [self performSegueWithIdentifier:@"mapViewSegue" sender:self];
}

// Retrieve flights from server
- (void) populateFlights {
    
    // Post request for the list of flights with unique id values
    NSError *error;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: [NSString stringWithFormat:@"https://afternoon-thicket-42652.herokuapp.com/"]]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPMethod: @"POST"];
    // Set mode to instruct server
    NSData *postData = [@"mode=getFlights" dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    
    // Parse json response
    NSURLResponse *response;
    NSData *responseData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    //NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSArray *flights = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
    
    // Display first 3 flights retrieved from database
    if ([flights count] > 0) {
        _flightButton1.alpha = 1;
        
        // Make flight info components visible
        _flightName1.alpha = 1;
        _flightLoc1.alpha = 1;
        _flightDesc1.alpha = 1;
        _flightBg1.alpha = 1;
        // Retrieve info components and populate label
        _flightID1 = [[flights objectAtIndex:0] objectForKey:@"id"];
        _flightName1.text = [[flights objectAtIndex:0] objectForKey:@"name"];
        _flightDesc1.text = [[flights objectAtIndex:0] objectForKey:@"description"];
        _flightLoc1.text = [[flights objectAtIndex:0] objectForKey:@"location"];
        if ([flights count] > 1) {
            _flightButton2.alpha = 1;
            _flightName2.alpha = 1;
            _flightLoc2.alpha = 1;
            _flightDesc2.alpha = 1;
            _flightBg2.alpha = 1;
            _flightID2 = [[flights objectAtIndex:1] objectForKey:@"id"];
            _flightName2.text = [[flights objectAtIndex:1] objectForKey:@"name"];
            _flightDesc2.text = [[flights objectAtIndex:1] objectForKey:@"description"];
            _flightLoc2.text = [[flights objectAtIndex:1] objectForKey:@"location"];
            if ([flights count] > 2) {
                _flightButton3.alpha = 1;
                _flightName3.alpha = 1;
                _flightLoc3.alpha = 1;
                _flightDesc3.alpha = 1;
                _flightBg3.alpha = 1;
                _flightID3 = [[flights objectAtIndex:([flights count]-1)] objectForKey:@"id"];
                _flightName3.text = [[flights objectAtIndex:([flights count]-1)] objectForKey:@"name"];
                _flightDesc3.text = [[flights objectAtIndex:([flights count]-1)] objectForKey:@"description"];
                _flightLoc3.text = [[flights objectAtIndex:([flights count]-1)] objectForKey:@"location"];
            }
        }
    }
}
@end
