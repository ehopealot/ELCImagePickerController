//
//  AssetTablePicker.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
@class ELCAsset;
@interface ELCAssetTablePicker : UIViewController
{
	ALAssetsGroup *assetGroup;
	
	NSMutableArray *elcAssets;
	int selectedAssets;
	
	id parent;
	
	NSOperationQueue *queue;
}

@property (nonatomic, assign) id parent;
@property (nonatomic, retain) ALAssetsGroup *assetGroup;
@property (nonatomic, retain) NSMutableArray *elcAssets;
@property (nonatomic, retain) IBOutlet UILabel *selectedAssetsLabel;
@property (nonatomic) BOOL reloadData;
@property (retain, nonatomic) IBOutlet UIView *footerMenuView;
@property (assign, nonatomic) IBOutlet UITableView *tableView;
@property (assign, nonatomic) IBOutlet UIButton *doneButton;
@property (assign, nonatomic) IBOutlet UIButton *chooseAlbumButton;
@property (nonatomic, retain) NSString *albumName;
@property (assign, nonatomic) IBOutlet UIButton *backButton;
@property (assign, nonatomic) IBOutlet UIButton *locationButton;
@property (assign, nonatomic) UILabel *counterLabel;
@property (nonatomic) BOOL pickVideo;
- (IBAction)goBack:(id)sender;
- (IBAction)locationButtonPressed:(id)sender;
-(int)totalSelectedAssets;
-(void)preparePhotos;

-(IBAction)doneAction:(id)sender;
- (IBAction)chooseAlbumPressed:(id)sender;
-(void)asset:(ELCAsset*)asset selectionChanged:(BOOL)selection;

@end


extern NSString * const ELCAssetTablePickerChooseAlbumButtonPressedNotification;
extern NSString * const ELCAssetTablePickerBecameVisibleNotification;
extern NSString * const ELCAssetTablePickerChangedLocationPreferenceNotification;