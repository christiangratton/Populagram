//
//  CGPhotoBrowser.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "PBViewProtocol.h"
#import "PBReloadViewProtocol.h"
#import "PBOptionsProtocol.h"

@class PBCell;
@class PBDetailView;
@class PBReloadView;
@class CGPhotoMap;
@class PBOptions;

@interface CGPhotoBrowser : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, PBViewProtocol, PBReloadViewProtocol, PBOptionsProtocol> {
    UIView *displayView;
    PBDetailView *detailView;
    
    NSCache *photoCache;
    NSCache *profileCache;
    
    NSOperationQueue *imagePreloadQ;
    NSMutableArray *objQueue;
    NSMutableArray *newIndexPaths;
    int totalObjects;
    
    float lastContentOffset;
    
    PBReloadView *reloadView;
    BOOL isLoadingMore;
    
    UIButton *optionsBtn;
    
    BOOL loadFavorites;
    BOOL needsRefresh;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) CGPhotoMap *photoMap;
@property (nonatomic, retain) PBOptions *options;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

- (void) toggleOptions;
- (void) showOptions;
- (void) hideOptions;

- (void) fetchPosts;
- (void) downloadPosts;

- (void) showLoadingMore;

- (void) configureCell:(PBCell*)cell atIndexPath:(NSIndexPath*)indexPath;
- (void) configureCellAtIndexPath:(NSIndexPath*)indexPath;

- (void) preloadImages;
- (void) preloadImageAtIndexPath:(NSIndexPath*)indexPath;
- (void) preloadImageAtIndexPath:(NSIndexPath*)indexPath withContext:(NSManagedObjectContext*)context;

@end
