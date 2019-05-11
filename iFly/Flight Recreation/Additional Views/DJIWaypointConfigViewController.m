//
//  DJIWaypointConfigViewController.m
//  iFly
//
//  Created by Mike Buzzard on 3/23/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import "DJIWaypointConfigViewController.h"
@interface DJIWaypointConfigViewController ()
@end

@implementation DJIWaypointConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI]; // Initialize UI when view loads
    [_altitudeTextField setDelegate:(id)self];
    [_autoFlightSpeedTextField setDelegate:(id)self];
    [_maxFlightSpeedTextField setDelegate: (id)self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Initialize the fields of the UI
- (void)initUI
{
    self.altitudeTextField.text = @"100"; //Set the altitude to 100
    self.autoFlightSpeedTextField.text = @"8"; //Set the autoFlightSpeed to 8
    self.maxFlightSpeedTextField.text = @"10"; //Set the maxFlightSpeed to 10
    [self.actionSegmentedControl setSelectedSegmentIndex:1]; //Set the finishAction to DJIWaypointMissionFinishedGoHome
    [self.headingSegmentedControl setSelectedSegmentIndex:0]; //Set the headingMode to DJIWaypointMissionHeadingAuto
    
}

- (IBAction)cancelBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(cancelBtnActionInDJIWaypointConfigViewController:)]) {
        [_delegate cancelBtnActionInDJIWaypointConfigViewController:self];
    }
}

- (IBAction)finishBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(finishBtnActionInDJIWaypointConfigViewController:)]) {
        [_delegate finishBtnActionInDJIWaypointConfigViewController:self];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
