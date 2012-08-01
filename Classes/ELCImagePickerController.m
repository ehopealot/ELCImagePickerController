//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by Collin Ruffenach on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "ELCAssetTablePicker.h"
#import "ELCAlbumPickerController.h"

@implementation ELCImagePickerController

@synthesize delegate, assets=assets;

-(void)cancelImagePicker {
	if([delegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[delegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

-(void)selectedAssets:(NSArray*)_assets {
    assets = _assets;
    if ([delegate respondsToSelector:@selector(elcImagePickerController:willFinishPickingThisManyMediaItems:)]){
        [self.delegate elcImagePickerController:self
            willFinishPickingThisManyMediaItems:[NSNumber numberWithInt:_assets.count]];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        for(ALAsset *asset in _assets) {
            @autoreleasepool {
                

            NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
            [workingDictionary setObject:[asset valueForProperty:ALAssetPropertyType] forKey:@"UIImagePickerControllerMediaType"];
            [workingDictionary setObject:[UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]] forKey:@"UIImagePickerControllerOriginalImage"];
            [workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:@"UIImagePickerControllerReferenceURL"];
            [workingDictionary setObject:asset forKey:@"ELCImagePickerControllerAsset"];
            if([delegate respondsToSelector:@selector(elcImagePickerController:hasMediaWithInfo:)]){
                    [delegate elcImagePickerController:self hasMediaWithInfo:workingDictionary];
            }
            [workingDictionary release];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self popToRootViewControllerAnimated:NO];
            //[[self parentViewController] dismissModalViewControllerAnimated:YES];
        });

    });
}



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {    
    NSLog(@"ELC Image Picker received memory warning.");
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
    NSLog(@"deallocing ELCImagePickerController");
    [super dealloc];
}

@end
