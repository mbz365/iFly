//
//  GSButtonControllerViewController.m
//  iFly
//
//  Created by Mike Buzzard on 3/16/19.
//  Copyright © 2019 Mike Buzzard. All rights reserved.
//

#import "GSButtonViewController.h"

@implementation GSButtonViewController

// Initialize mode to view mode on load
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setMode:GSViewMode_ViewMode];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// Set up buttons to be properly displayed in view mode
- (void)setMode:(GSViewMode)mode
{
    _mode = mode;
    [_editBtn setHidden:(mode == GSViewMode_EditMode)];
    [_focusMapBtn setHidden:(mode == GSViewMode_EditMode)];
    [_backBtn setHidden:(mode == GSViewMode_ViewMode)];
    [_clearBtn setHidden:(mode == GSViewMode_ViewMode)];
    [_startBtn setHidden:(mode == GSViewMode_ViewMode)];
    [_stopBtn setHidden:(mode == GSViewMode_ViewMode)];
    [_addBtn setHidden:(mode == GSViewMode_ViewMode)];
    [_configBtn setHidden:(mode == GSViewMode_ViewMode)];
}

// Back button changes modes
- (IBAction)backBtnAction:(id)sender {
    [self setMode:GSViewMode_ViewMode];
    if ([_delegate respondsToSelector:@selector(switchToMode:inGSButtonVC:)]) {
        [_delegate switchToMode:self.mode inGSButtonVC:self];
    }
}

- (IBAction)stopBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(stopBtnActionInGSButtonVC:)]) {
        [_delegate stopBtnActionInGSButtonVC:self];
    }
}

- (IBAction)clearBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(clearBtnActionInGSButtonVC:)]) {
        [_delegate clearBtnActionInGSButtonVC:self];
    }
}

- (IBAction)focusMapBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(focusMapBtnActionInGSButtonVC:)]) {
        [_delegate focusMapBtnActionInGSButtonVC:self];
    }
}

- (IBAction)editBtnAction:(id)sender {
    [self setMode:GSViewMode_EditMode];
    if ([_delegate respondsToSelector:@selector(switchToMode:inGSButtonVC:)]) {
        [_delegate switchToMode:self.mode inGSButtonVC:self];
    }
}

- (IBAction)startBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(startBtnActionInGSButtonVC:)]) {
        [_delegate startBtnActionInGSButtonVC:self];
    }
}

- (IBAction)addBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(addBtn:withActionInGSButtonVC:)]) {
        [_delegate addBtn:self.addBtn withActionInGSButtonVC:self];
    }
}

- (IBAction)configBtnAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(configBtnActionInGSButtonVC:)]) {
        [_delegate configBtnActionInGSButtonVC:self];
    }
}

@end
