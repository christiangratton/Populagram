//
//  CGPhotoBrowser.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "CGPhotoBrowser.h"
#import "PBDetailView.h"
#import "CGDataManager.h"
#import "UIImageManipulator.h"
#import "Post.h"
#import "User.h"
#import "Image.h"
#import "Link.h"
#import "PBCell.h"
#import "PBView.h"

#import "CGActivityView.h"
#import "PBReloadView.h"
#import "CGPhotoMap.h"
#import "PBOptions.h"

#define ROW_HEIGHT 350
#define LOADING_VIEW_HEIGHT 50
#define MAX_PRELOAD 15
#define POPULAR_API_URL @"https://api.instagram.com/v1/media/popular?client_id=YOUR_CLIENT_ID"

@interface CGPhotoBrowser ()

@end

@implementation CGPhotoBrowser
@synthesize tableView = _tableView, photoMap = _photoMap, options = _options, managedObjectContext, fetchedResultsController;

- (id)init {
    self = [super init];
    if (self) {
        
        [self.view setBackgroundColor:[UIColor whiteColor]];
        
        // Display view, since we only switch from one view to another, we add the controls inside this view and keep the button, options always on top
        displayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
        [displayView setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:displayView];
        
        // Table View (Popular + Favorites)
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setHidden:YES];
        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [displayView addSubview:_tableView];
        
        // Reload view at bottom
        reloadView = [[PBReloadView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, LOADING_VIEW_HEIGHT)];
        [reloadView setDelegate:self];
        
        // Photo Map (Photo Map)
        _photoMap = [[CGPhotoMap alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
        [_photoMap setHidden:YES];
        [displayView insertSubview:_photoMap belowSubview:_tableView];        
        
        // Detail view
        detailView = [[PBDetailView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
        
        // Option view
        _options = [[PBOptions alloc] initWithFrame:CGRectMake(0.0, -50, 320, 50)];
        [_options setDelegate:self];
        [self.view addSubview:_options];
        
        optionsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [optionsBtn setImage:[UIImage imageNamed:@"options.png"] forState:UIControlStateNormal];
        [optionsBtn setHidden:YES];
        [optionsBtn addTarget:self action:@selector(toggleOptions) forControlEvents:UIControlEventTouchUpInside];
        [optionsBtn setFrame:CGRectMake(self.view.frame.size.width - (50 + 10), self.view.frame.size.height - (50 + 10), 50, 50)];
        [self.view addSubview:optionsBtn];
        
        // Queue to preload images
        imagePreloadQ = [[NSOperationQueue alloc] init];
        [imagePreloadQ setMaxConcurrentOperationCount:5];
        [imagePreloadQ setName:@"Image Preloading Queue"];
        objQueue = [[NSMutableArray alloc] init];
        totalObjects = 0;
    }
    return self;
}

// Helper to toggle options
- (void) toggleOptions {
    if(_options.alpha == 0.0) [self showOptions];
    else [self hideOptions];
}

- (void) showOptions {
    [UIView beginAnimations:@"ShowOptions" context:nil];
    [UIView animateWithDuration:0.75f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         _options.alpha = 1.0;
                         [_options setFrame:CGRectMake(_options.frame.origin.x, 0.0, _options.frame.size.width, _options.frame.size.height)];
                     }
                     completion:^(BOOL finished){
                         // Auto hide options
                         [self performSelector: @selector(hideOptions)
                                    withObject: nil
                                    afterDelay: 5.0];
                     }];
    [UIView commitAnimations];
}

- (void) hideOptions {
    // If option already hidden, cancel request to hide
    [NSObject cancelPreviousPerformRequestsWithTarget: self
                                             selector: @selector(hideOptions)
                                               object: nil];
    
    [UIView beginAnimations:@"HideOptions" context:nil];
    [UIView animateWithDuration:0.75f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         _options.alpha = 0.0;
                         [_options setFrame:CGRectMake(_options.frame.origin.x, -_options.frame.size.height, _options.frame.size.width, _options.frame.size.height)];
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
}

// Get the post by envoking performFetch
- (void) fetchPosts {
    
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    // If we need a refresh (for switch between favorite <-> posts)
    if(needsRefresh) [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    // Start preloading images now to ensure fast scrolling
    [self preloadImages];
}

// Downloads the posts
- (void) downloadPosts {
    [CGDataManager requestForURL:POPULAR_API_URL];
}

// Add the load more at the bottom of the view
- (void) showLoadingMore {
    CGRect rect = [_tableView rectForFooterInSection:0];
    CGRect reloadViewFrame = CGRectZero;
    reloadViewFrame.origin.x = reloadView.frame.origin.x;
    reloadViewFrame.origin.y = rect.origin.y;
    reloadViewFrame.size.width = reloadView.frame.size.width;
    reloadViewFrame.size.height = reloadView.frame.size.height;
    reloadView.frame = reloadViewFrame;
    [_tableView addSubview:reloadView];
    
    [_tableView setContentSize:CGSizeMake(_tableView.contentSize.width, _tableView.contentSize.height + LOADING_VIEW_HEIGHT)];
}

// Cast the cell to right type and configure
- (void) configureCellAtIndexPath:(NSIndexPath*)indexPath {
    [self configureCell:(PBCell*)[_tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}

// Confiure cell
- (void) configureCell:(PBCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    Post *post = [fetchedResultsController objectAtIndexPath:indexPath];
    [cell setPost:post];
    
    // Get images
    UIImage *photo = [photoCache objectForKey:post.objectID];
    UIImage *profile = [profileCache objectForKey:post.objectID];
    
    // Only photo is checked here because it's bigger and the "must"
    if(!photo)
    {
        [self preloadImageAtIndexPath:indexPath];
        
        [cell setPostImage:nil];
        [cell setProfilePicture:profile];
    }
    else
    {
        [cell setPostImage:photo];
        [cell setProfilePicture:profile];
    }
}

- (void) preloadImages {
    // We only have one section
    id  sectionInfo = [[fetchedResultsController sections] objectAtIndex:0];
    totalObjects = [sectionInfo numberOfObjects];
    
    // Table view has loaded, show what needs to be seen
    if(totalObjects > 0)
    {
        [_tableView setHidden:NO];
        [_photoMap setHidden:NO];
        [optionsBtn setHidden:NO];
        [CGActivityView remove];
    }
    
    // Preloads the first 10 rows, helps to start the app
    for(int i = 0; i < (MAX_PRELOAD > totalObjects ? totalObjects : MAX_PRELOAD); i++)
    {
        [self preloadImageAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
}

// Creates the background context and preloads
- (void) preloadImageAtIndexPath:(NSIndexPath*)indexPath {
    
    if(_tableView.isHidden) {
        [_tableView setHidden:NO];
        [_photoMap setHidden:NO];
        [optionsBtn setHidden:NO];
    }
    
    NSManagedObjectContext *bgcontext = [[[NSManagedObjectContext alloc] init] autorelease];
    [bgcontext setPersistentStoreCoordinator:[managedObjectContext persistentStoreCoordinator]];
    
    [self preloadImageAtIndexPath:indexPath withContext:bgcontext];
}

// Preloads on a seperate operation queue
- (void) preloadImageAtIndexPath:(NSIndexPath*)indexPath withContext:(NSManagedObjectContext*)context {
    Post *post = [fetchedResultsController objectAtIndexPath:indexPath];
    NSManagedObjectID *objID = post.objectID;
    
    UIImage *photo = [photoCache objectForKey:objID];
    UIImage *profile = [profileCache objectForKey:objID];
    
    // It doesn't really matter which, cache both
    if(!photo || !profile) {
        if([objQueue containsObject:objID]) return;
        // Array that keeps track of images already in the queue
        [objQueue addObject:objID];
                
        [imagePreloadQ addOperationWithBlock:^{
        
            NSManagedObject *object = [context objectWithID:objID];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %@", @"standard_resolution"];
            NSSet *set = [((Post*)object).images filteredSetUsingPredicate:predicate];
            
            Image *pImage = [set anyObject]; // Should only return one
            
            // At this point the images aren't cache on the device, they will need to be downloaded
            UIImage *cPhoto = [UIImageManipulator imageWithImage:[CGDataManager getImage:pImage.path from:pImage.url] scaledToSize:CGSizeMake(290, 290)];
            
            User *user = (User*)((Post*)object).user;
            
            UIImage *cProfile = [UIImageManipulator imageWithImage:[CGDataManager getImage:user.path from:user.url] scaledToSize:CGSizeMake(57.5, 57.5)];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                [photoCache setObject:cPhoto forKey:objID];
                [profileCache setObject:cProfile forKey:objID];
                // Remove object so we know it's done
                [objQueue removeObject:objID];
                
                if([[_tableView indexPathsForVisibleRows] containsObject:indexPath]) {
                    PBCell *photoBrowserCell = (PBCell*)[_tableView cellForRowAtIndexPath:indexPath];
                    [photoBrowserCell setPostImage:cPhoto];
                    [photoBrowserCell setProfilePicture:cProfile];
                    [photoBrowserCell redisplay];
                }
            }];            
        }];
    } else {
        // Remove object so we know it's done
        if([objQueue containsObject:objID]) [objQueue removeObject:objID];
    }
}

#pragma mark - PBView Delegate

// Like/comment button was pressed. From here, a modal view could be presented
- (void) showInteractionsForPost:(Post *)aPost {
    NSLog(@"Show likes and comment view controller");
}

// Share button was pressed, from here, a modal view could be presented
- (void) showShareOptionsForPost:(Post*)aPost {
    
    // Get the highest res image
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %@", @"standard_resolution"];
    NSSet *set = [aPost.images filteredSetUsingPredicate:predicate];
    
    // Format
    Image *image = [set anyObject];   
    UIImage *imageToShare = [CGDataManager getImage:image.path from:image.url];
    NSString *linkToShare = [NSString stringWithFormat:@"%@", ((Link*)aPost.link).url];
    
    NSArray *activityItems = @[imageToShare, linkToShare];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:Nil];
    //This is an array of excluded activities to appear on the UIActivityViewController
    activityController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll, UIActivityTypePostToWeibo];
    [self presentViewController:activityController animated:TRUE completion:nil];
}

// Display the detail view
- (void) showImageForPost:(Post*)aPost {
    [detailView setPost:aPost];
    [detailView showIn:self.view];
}

#pragma mark - PBReloadView delegate

// Load more posts was push...
- (void) loadMorePosts {
    [self downloadPosts];
}

#pragma mark - PBOptions delegate

// Option was selected, display accordingly
- (void) selectedOptionIndex:(int)index {
    
    switch (index) {
        case 0: {
            [displayView bringSubviewToFront:_tableView]; // Bring to front
            
            // If we were looking at favorites, reload the fetched results controller
            if(loadFavorites) {
                self.fetchedResultsController = nil;
                loadFavorites = NO; // No predicate
                needsRefresh = YES; // We refresh
                [self fetchPosts]; // Fetch
            }
            break;
        }
        
        case 1:
            [_photoMap fetchPosts]; // Fetch posts on map
            [displayView bringSubviewToFront:_photoMap]; // Bring to front
            break;
            
        case 2: {
            [displayView bringSubviewToFront:_tableView]; // Bring to front
            
            // If we weren't looking at favorites, reload
            if(!loadFavorites) {
                self.fetchedResultsController = nil;
                loadFavorites = YES; // Predicate
                needsRefresh = YES; // Refresh table view
                [self fetchPosts]; // Fetch posts
            }
            break;
        }
        
        default:
            break;
    }
    
    // Hide options
    [self hideOptions];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    id  sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return ROW_HEIGHT; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    PBCell *photoBrowserCell = (PBCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(photoBrowserCell == nil) {
        photoBrowserCell = [[[PBCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        [photoBrowserCell setFrame:CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT)];
        [photoBrowserCell.photoBrowserView setDelegate:self];
    }
    
    // Configure cell
    [self configureCell:photoBrowserCell atIndexPath:indexPath];
    
    return photoBrowserCell;
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { [tableView deselectRowAtIndexPath:indexPath animated:YES]; }

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // If options are shown, hide
    [self hideOptions];
    
    [UIView beginAnimations:@"HideOptionsForScroll" context:nil];
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         optionsBtn.alpha = 0.2;
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    // Try to preload and configure cells if they haven't been already
    // This should help the scroll on slower devices and long lists
    for(NSIndexPath *indexPath in [_tableView indexPathsForVisibleRows])
    {
        int increment = 0;
        if(lastContentOffset > scrollView.contentOffset.y) {
            // Up
            if((indexPath.row - 2) > 0) increment = -2;
            else if((indexPath.row - 1) > 0) increment = -1;
            
        } else {
            // Down
            if((indexPath.row + 2) < totalObjects) increment = 2;
            else if((indexPath.row + 1) < totalObjects) increment = 1;
        }
        
        indexPath = [[indexPath indexPathByRemovingLastIndex] indexPathByAddingIndex:indexPath.row+increment];
        
        [self preloadImageAtIndexPath:indexPath];
    }
    
    // Detects when near bottom
    CGFloat height = scrollView.frame.size.height;
    CGFloat contentYoffset = scrollView.contentOffset.y;
    CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
    
    if(distanceFromBottom <= height && !isLoadingMore && !loadFavorites) {
        isLoadingMore = YES;
        [self showLoadingMore];
    }
    
    lastContentOffset = scrollView.contentOffset.y;
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // If animating into position, don't show just yet
    if(!decelerate) {
        [UIView beginAnimations:@"HideOptionsForScrollEnded" context:nil];
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             optionsBtn.alpha = 1.0;
                         }
                         completion:^(BOOL finished){
                         }];
        [UIView commitAnimations];
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [UIView beginAnimations:@"HideOptionsForScrollEnded" context:nil];
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         optionsBtn.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
}

#pragma mark - fetchedResultsController

// Fetches the core data objects
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:managedObjectContext];
    
    if(loadFavorites) fetchRequest.predicate = [NSPredicate predicateWithFormat:@"favorite == YES"];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setFetchBatchSize:5];
    [sort release];
    
    NSFetchedResultsController *theFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    fetchedResultsController.delegate = self;
    
    [fetchRequest release];
    [theFetchedResultsController release];
    
    return fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates
    [_tableView beginUpdates];
    [reloadView removeFromSuperview]; // Remove reload view
}

// Inserts/removes accordingly
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    if(newIndexPath) [newIndexPaths addObject:newIndexPath];
    UITableView *tableView = _tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCellAtIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

// Inserts/removes accordingly
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [_tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationBottom];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [_tableView endUpdates];
    
    // Request to preload images (if needed)    
    for(NSIndexPath *indexPath in newIndexPaths)
    {
        [self preloadImageAtIndexPath:indexPath];
    }
    
    [newIndexPaths removeAllObjects];
    [CGActivityView remove];
    isLoadingMore = NO;
    [reloadView reset];
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
    photoCache = [[NSCache alloc] init];
    profileCache = [[NSCache alloc] init];
    newIndexPaths = [[NSMutableArray alloc] init];
    
    // Only download once, user can auto load after
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"fLaunch"]) {
        [self downloadPosts];
        
#warning set bool to NO or comment if statement to reload (which adds more, no delete) on each start
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"fLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

// Add acitivity view, fetch posts, and set managed object context on photo map
- (void) viewWillAppear:(BOOL)animated {
    [CGActivityView activityViewFor:self.view];
    [self fetchPosts];
    
    [_photoMap setManagedObjectContext:managedObjectContext];
}

- (void)didReceiveMemoryWarning {
    
    // We received a memory warning, clear caches
    [photoCache removeAllObjects];
    [profileCache removeAllObjects];
    
    [super didReceiveMemoryWarning];
}

- (void) dealloc {
    [imagePreloadQ release];
    [objQueue release];
    [photoCache release];
    [profileCache release];
    [newIndexPaths release];
    [displayView release];
    [_tableView release];
    [reloadView release];
    [_photoMap release];
    [detailView release];
    [_options release];
    [fetchedResultsController release];
    
    [super dealloc];
}

@end
