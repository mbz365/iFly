//
//  SaveFlightViewController.h
//  iFly
//
//  Created by Mike Buzzard on 4/2/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SaveFlightViewController;

@protocol SaveFlightViewControllerDelegate <NSObject, UITextFieldDelegate>

- (void)cancelBtnActionInSaveFlightViewController:(SaveFlightViewController *)saveFlightVC;
- (void)saveBtnActionInSaveFlightViewController:(SaveFlightViewController *)saveFlightVC;

@end

@interface SaveFlightViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;
@property (weak, nonatomic) IBOutlet UITextView *descTextField;
- (IBAction)cancelBtnAction:(id)sender;
- (IBAction)saveBtnAction:(id)sender;

@property (weak, nonatomic) id <SaveFlightViewControllerDelegate>delegate;

@end

NS_ASSUME_NONNULL_END
