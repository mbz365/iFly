//
//  LoggedInViewController.m
//  iFly
//
//  Created by Mike Buzzard on 4/27/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import "LoggedInViewController.h"
#import "FlightSearchViewController.h"
#import "CreateFlightsViewController.h"

@interface LoggedInViewController ()
@property (weak, nonatomic) IBOutlet UILabel *userLabel;

@end

@implementation LoggedInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userLabel.text = self.currentUser.username;
}
- (IBAction)createFlightsButtonAction:(id)sender {
    [self performSegueWithIdentifier:@"createFlightsSegue" sender:self];
}
- (IBAction)browseFlightsButtonAction:(id)sender {
    [self performSegueWithIdentifier:@"browseFlightsSegue" sender:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"browseFlightsSegue"]) {
        FlightSearchViewController *vc = [segue destinationViewController];
        vc.currentUser = self.currentUser;
        NSLog(@"%@", vc.currentUser);
    }
    else if ([segue.identifier isEqualToString:@"createFlightsSegue"]) {
        CreateFlightsViewController *vc = [segue destinationViewController];
        vc.currentUser = self.currentUser;
    }
}


@end
