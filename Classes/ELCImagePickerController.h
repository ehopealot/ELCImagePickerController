//
//  ELCImagePickerController.h
//  ELCImagePickerDemo
//
//  Created by Collin Ruffenach on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ELCImagePickerController : UINavigationController {

	id delegate;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) NSArray *assets;

-(void)selectedAssets:(NSArray*)_assets caption:(NSString *)caption;
-(void)cancelImagePicker;

@end

@protocol ELCImagePickerControllerDelegate


- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithAssets:(NSArray *)info caption:(NSString*)caption;
- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker;

@end

