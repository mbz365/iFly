//
//  SaveFlightViewController.m
//  iFly
//
//  Created by Mike Buzzard on 3/29/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import "SaveFlightViewController.h"

@interface SaveFlightViewController ()
@end

@implementation SaveFlightViewController

// Initial setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Enable keyboard dismissal
    [_nameTextField setDelegate:(id)self];
    [_descTextField setDelegate:(id)self];
}

// Set delegate for cancel button
- (IBAction)cancelBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(cancelBtnActionInSaveFlightViewController:)]) {
        [_delegate cancelBtnActionInSaveFlightViewController:self];
    }
    
}

// Set delegate for save button
- (IBAction)saveBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(saveBtnActionInSaveFlightViewController:)]) {
        [_delegate saveBtnActionInSaveFlightViewController:self];
    }
}

// Dismiss keyboard when return button is pressed
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
