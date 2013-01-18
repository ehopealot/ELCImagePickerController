//
//  AssetTablePicker.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import <QuartzCore/QuartzCore.h>
NSString * const ELCAssetTablePickerChooseAlbumButtonPressedNotification = @"ELCAssetTablePickerChooseAlbumButtonPressedNotification";
NSString * const ELCAssetTablePickerBecameVisibleNotification = @"ELCAssetTablePickerBecameVisibleNotification";
NSString * const ELCAssetTablePickerChangedLocationPreferenceNotification = @"ELCAssetTablePickerChangedLocationPreferenceNotification";

@implementation ELCAssetTablePicker
{
    NSInteger start;
    UIBarButtonItem *doneButtonItem;
    BOOL captionViewShown;
}
@synthesize parent;
@synthesize selectedAssetsLabel;
@synthesize assetGroup, doneButton, elcAssets, reloadData, footerMenuView, tableView, backButton, albumName, locationButton, counterLabel;

-(void)viewDidLoad {
    self.reloadData = YES;
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
	//doneButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
//    NSArray *navigationItems = @[doneButtonItem];// NO SELECT ALL, selectAllButtonItem];
//    [self.navigationItem setRightBarButtonItems:navigationItems];
	[self.navigationItem setTitle:self.pickVideo?@"Pick A Video": @"Pick Photos"];
    NSInteger count = self.assetGroup.numberOfAssets;
    NSInteger startNumberOfAssets = 500 + count%4;
    start = MAX(0, count-startNumberOfAssets);
    // Set up the first ~100 photos
//    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, count > startNumberOfAssets ? startNumberOfAssets : count)];
    for (int i = 0; i < self.assetGroup.numberOfAssets; i++){
        [self.elcAssets addObject:[NSNull null]];
    }
//    [self.assetGroup enumerateAssetsAtIndexes:indexSet options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
//        if(result == nil) 
//        {
//            return;
//        }
//        ELCAsset *elcAsset = [[[ELCAsset alloc] initWithAsset:result] autorelease];
//        [elcAsset setParent:self];
//        [self.elcAssets addObject:elcAsset];
//    }];
//    [self.tableView reloadData];
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:MAX(0,ceil(assetGroup.numberOfAssets / 4.0)-1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
    // For some reason it only scrolls about 80% through the final image... This scrolls
    // the table view all the way to the bottom. 50 is just a number thats bigger than the 
    // sliver of the image thats covered up.
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y+50)];

//	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
    self.navigationItem.hidesBackButton = YES;
    self.backButton.layer.borderColor = [UIColor colorWithRed:151.f/255.f green:151.f/255.f blue:149.f/255.f alpha:1.f].CGColor;
    self.backButton.layer.borderWidth = 1.f;
    self.backButton.layer.cornerRadius = 5.f;
    self.chooseAlbumButton.layer.cornerRadius = 5.f;
    UILabel *myCounterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80.f, 40.f)];
    if (self.pickVideo){
        myCounterLabel.text = @"0/1";
    } else {
        myCounterLabel.text = @"0/25";
    }
    myCounterLabel.font = [UIFont fontWithName:@"Gotham-Book" size:14.f];
    myCounterLabel.textColor = [UIColor colorWithRed:250.f/255.f green:250.f/255.f blue:250.f/255.f alpha:1.f];
    myCounterLabel.textAlignment = UITextAlignmentRight;
    myCounterLabel.backgroundColor = [UIColor clearColor];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:myCounterLabel];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    [barButtonItem release];
    self.counterLabel = myCounterLabel;
    [myCounterLabel release];
    self.doneButton.layer.cornerRadius = 5.f;
    captionViewShown = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:ELCAssetTablePickerBecameVisibleNotification object:self];
    if (self.albumName){
        [self.chooseAlbumButton setTitle:[NSString stringWithFormat:@"%@", self.albumName] forState:UIControlStateNormal];
        [self.doneButton setImage:[UIImage imageNamed:@"green_check.png"] forState:UIControlStateNormal];
    } else {
        [self.chooseAlbumButton setTitle:@"New Album" forState:UIControlStateNormal];
        [self.doneButton setImage:[UIImage imageNamed:@"green_caret.png"] forState:UIControlStateNormal];
    }
    if (self.totalSelectedAssets > 0){
        [self enableDoneButton:YES];
    }else {
        [self enableDoneButton:NO];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardAppeared:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDisappeared:) name:UIKeyboardWillHideNotification object:nil];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)preparePhotos {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	
    NSLog(@"enumerating photos");

    NSIndexSet *newIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, start)];
    [self.assetGroup enumerateAssetsAtIndexes:newIndexSet options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result == nil) 
        {
            return;
        }
        ELCAsset *elcAsset = [[[ELCAsset alloc] initWithAsset:result] autorelease];
        [elcAsset setParent:self];
        [self.elcAssets replaceObjectAtIndex:index withObject:elcAsset];
    }];
    NSLog(@"done enumerating photos");
    [self.navigationItem performSelectorOnMainThread:@selector(setTitle:) withObject:@"Pick Photos" waitUntilDone:NO];
    [pool release];

}

- (void) doneAction:(id)sender {
	
	NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
    NSArray *currentlyLoadedAssets = [self.elcAssets copy];
	for(ELCAsset *elcAsset in currentlyLoadedAssets) 
    {		
		if(elcAsset != (id)[NSNull null] && [elcAsset selected]) {
			
			[selectedAssetsImages insertObject:[elcAsset asset] atIndex:0];
		}
	}
    NSString *caption = nil;
    if (captionViewShown && [self.captionView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0){
        caption = [self.captionView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages caption:caption];
}

- (IBAction)chooseAlbumPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ELCAssetTablePickerChooseAlbumButtonPressedNotification object:self];
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ceil(assetGroup.numberOfAssets / 4.0);
}

- (NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath {
    
	int index = (_indexPath.row*4);
	int maxIndex = (_indexPath.row*4+3);
    BOOL needsToEnumerate = NO;
	// NSLog(@"Getting assets for %d to %d with array count %d", index, maxIndex, [assets count]);
    for (int i = index; i < MIN(maxIndex, self.elcAssets.count); i++){
        if ([self.elcAssets objectAtIndex:i] == [NSNull null]){
            needsToEnumerate = YES;
            break;
        }
    }
    
    if (needsToEnumerate){
        [self.assetGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, MIN(maxIndex+1-index, self.elcAssets.count-index))] options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result == nil)
            {
                return;
            }
            ELCAsset *elcAsset = [[[ELCAsset alloc] initWithAsset:result] autorelease];
            [elcAsset setParent:self];
            [self.elcAssets replaceObjectAtIndex:index withObject:elcAsset];
        }];
    }
    
	if(maxIndex < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				[self.elcAssets objectAtIndex:index+3],
				nil];
	}
    
	else if(maxIndex-1 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				nil];
	}
    
	else if(maxIndex-2 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				nil];
	}
    
	else if(maxIndex-3 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObject:[self.elcAssets objectAtIndex:index]];
	}
    
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[theTableView dequeueReusableCellWithIdentifier:CellIdentifier];

    NSMutableArray *assets = [[self assetsForIndexPath:indexPath] mutableCopy];
    [assets removeObjectIdenticalTo:[NSNull null]];
    if (cell == nil) 
    {		        
        cell = [[[ELCAssetCell alloc] initWithAssets:assets reuseIdentifier:CellIdentifier] autorelease];
    }	
	else 
    {		
		[cell setAssets:assets];
	}
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	return 79;
}

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)locationButtonPressed:(id)sender {
    self.locationButton.selected = !self.locationButton.selected;
    [[NSNotificationCenter defaultCenter] postNotificationName:ELCAssetTablePickerChangedLocationPreferenceNotification object:self userInfo:@{@"LOCATION":@(!self.locationButton.selected)}];
}

- (int)totalSelectedAssets {
    
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) 
    {
		if(!((id)asset == [NSNull null]) &&  [asset selected])
        {            
            count++;	
		}
	}
    return count;
}

- (void)enableDoneButton:(BOOL)enabled
{
    self.doneButton.enabled = enabled;
    self.doneButton.hidden = !enabled;
}

- (void)asset:(ELCAsset *)asset selectionChanged:(BOOL)selection
{
    NSInteger numberOfSelectedAssets = self.totalSelectedAssets;
    if (numberOfSelectedAssets <= 0 ){
        [self enableDoneButton:NO];
    } else {
        [self enableDoneButton:YES];
    }
    if (numberOfSelectedAssets <= 1 && !captionViewShown){
        [self showCaptionField];
    } else if (captionViewShown && numberOfSelectedAssets > 1){
        [self hideCaptionField];
    }
    
    self.counterLabel.text = [NSString stringWithFormat:@"%i/%@", numberOfSelectedAssets, self.pickVideo? @1 : @25];
}

- (void)showCaptionField
{
    CGRect myTableviewFrame = self.tableView.frame;
    CGRect myCaptionViewFrame = self.captionView.frame;
    myTableviewFrame.size.height -= myCaptionViewFrame.size.height;
    myCaptionViewFrame.origin.y -= myCaptionViewFrame.size.height;
    [UIView animateWithDuration:.25 animations:^{
        self.tableView.frame = myTableviewFrame;
        self.captionView.frame = myCaptionViewFrame;
    }];
    captionViewShown = YES;
}

- (void)hideCaptionField
{
    CGRect myTableviewFrame = self.tableView.frame;
    CGRect myCaptionViewFrame = self.captionView.frame;
    myTableviewFrame.size.height += myCaptionViewFrame.size.height;
    myCaptionViewFrame.origin.y += myCaptionViewFrame.size.height;
    [UIView animateWithDuration:.25 animations:^{
        self.tableView.frame = myTableviewFrame;
        self.captionView.frame = myCaptionViewFrame;
    }];
    captionViewShown = NO;
}

- (void)dealloc 
{
    [elcAssets release];
    [selectedAssetsLabel release];
    [super dealloc];    
}

- (void)viewDidUnload {
    [self setFooterMenuView:nil];
    [self setDoneButton:nil];
    [self setChooseAlbumButton:nil];
    [self setDoneButton:nil];
    [self setLocationButton:nil];
    [self setCaptionView:nil];
    [super viewDidUnload];
}

- (void)keyboardAppeared:(NSNotification*)notification
{
    CGRect newFrame = self.captionView.frame;
    newFrame.origin.y = self.view.frame.size.height - [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height - newFrame.size.height;
    self.tableView.userInteractionEnabled = NO;
    [UIView animateWithDuration:.25f animations:^{
        self.captionView.frame = newFrame;
    }];
}

- (void)keyboardDisappeared:(NSNotification*)notification
{
    self.tableView.userInteractionEnabled = YES;
    [UIView animateWithDuration:.25f animations:^{
        CGRect newFrame = self.captionView.frame;
        newFrame.origin.y = CGRectGetMaxY(self.tableView.frame);
        self.captionView.frame = newFrame;
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return NO;
}

@end
