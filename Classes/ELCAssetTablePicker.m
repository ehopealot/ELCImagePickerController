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


@implementation ELCAssetTablePicker
{
    NSInteger start;
}
@synthesize parent;
@synthesize selectedAssetsLabel;
@synthesize assetGroup, elcAssets, reloadData;

-(void)viewDidLoad {
    self.reloadData = YES;
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
	UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
    UIBarButtonItem *selectAllButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectAllAction:)] autorelease];
    NSArray *navigationItems = @[doneButtonItem];// NO SELECT ALL, selectAllButtonItem];
    [self.navigationItem setRightBarButtonItems:navigationItems];
	[self.navigationItem setTitle:@"Loading..."];

    NSInteger count = self.assetGroup.numberOfAssets;
    NSInteger startNumberOfAssets = 96 + count%4;
    start = MAX(0, count-startNumberOfAssets);
    
    // Set up the first ~100 photos
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, count > startNumberOfAssets ? startNumberOfAssets : count)];
    for (int i = 0; i < start; i++){
        [self.elcAssets addObject:[NSNull null]];
    }
    [self.assetGroup enumerateAssetsAtIndexes:indexSet options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result == nil) 
        {
            return;
        }
        ELCAsset *elcAsset = [[[ELCAsset alloc] initWithAsset:result] autorelease];
        [elcAsset setParent:self];
        [self.elcAssets addObject:elcAsset];
    }];
    [self.tableView reloadData];

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:MAX(0,ceil(assetGroup.numberOfAssets / 4.0)-1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
    // For some reason it only scrolls about 80% through the final image... This scrolls
    // the table view all the way to the bottom. 50 is just a number thats bigger than the 
    // sliver of the image thats covered up.
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y+50)];

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
    
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

- (void)selectAllAction:(id)sender
{
    NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
    NSArray *currentlyLoadedAssets = [self.elcAssets copy];
    for (ELCAsset *asset in currentlyLoadedAssets)
    {
        if(asset != (id)[NSNull null]){
           [selectedAssetsImages addObject:[asset asset]];
        }
    }
    [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages];
}

- (void) doneAction:(id)sender {
	
	NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
    NSArray *currentlyLoadedAssets = [self.elcAssets copy];
	for(ELCAsset *elcAsset in currentlyLoadedAssets) 
    {		
		if(elcAsset != (id)[NSNull null] && [elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
    [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages];
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
    
	// NSLog(@"Getting assets for %d to %d with array count %d", index, maxIndex, [assets count]);
    
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
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

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

- (int)totalSelectedAssets {
    
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) 
    {
		if([asset selected]) 
        {            
            count++;	
		}
	}
    
    return count;
}

- (void)dealloc 
{
    [elcAssets release];
    [selectedAssetsLabel release];
    [super dealloc];    
}

@end
