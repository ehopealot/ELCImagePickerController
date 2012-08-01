//
//  ELCImagePickerDemoViewController.m
//  ELCImagePickerDemo
//
//  Created by Collin Ruffenach on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerDemoAppDelegate.h"
#import "ELCImagePickerDemoViewController.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation ELCImagePickerDemoViewController
{
    CGRect workingFrame;
}

@synthesize scrollview;

-(IBAction)launchController {
	
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]];    
	ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
    [albumController setParent:elcPicker];
	[elcPicker setDelegate:self];
    
    ELCImagePickerDemoAppDelegate *app = (ELCImagePickerDemoAppDelegate *)[[UIApplication sharedApplication] delegate];
	[app.viewController presentModalViewController:elcPicker animated:YES];
    [elcPicker release];
    [albumController release];
}

#pragma mark ELCImagePickerControllerDelegate Methods


- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithAssets:(NSArray*)assets {
	

    for (UIView *v in [scrollview subviews]) {
        [v removeFromSuperview];
    }
    
	workingFrame = scrollview.frame;
	workingFrame.origin.x = 0;
	
    [scrollview setPagingEnabled:YES];
    [self dismissModalViewControllerAnimated:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(ALAsset *asset in assets) {
            CGImageRef image = asset.defaultRepresentation.fullResolutionImage;
            CGImageRetain(image);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *imageview = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:image]];
                CGImageRelease(image);
                [imageview setContentMode:UIViewContentModeScaleAspectFit];
                imageview.frame = workingFrame;
                
                [scrollview addSubview:imageview];
                [imageview release];
                
                workingFrame.origin.x = workingFrame.origin.x + workingFrame.size.width;

            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [scrollview setPagingEnabled:YES];
            [scrollview setContentSize:CGSizeMake(workingFrame.origin.x, workingFrame.size.height)];
        });
    });
	
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {

	[self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
