//
//  RZCollectionListTableViewDataSource.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionList.h"

@protocol RZCollectionListDataSourceDelegate <NSObject>

@required
- (UITableViewCell*)tableView:(UITableView*)tableView cellForObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@optional
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;

- (BOOL)tableView:(UITableView*)tableView canEditObject:(id)object atIndexPath:(NSIndexPath*)indexPath;
- (BOOL)tableView:(UITableView*)tableView canMoveObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end

@interface RZCollectionListTableViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong, readonly) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readonly) UITableView *tableView;

@property (nonatomic, weak) id<RZCollectionListDataSourceDelegate> delegate;

@property (nonatomic, assign, getter = shouldShowTableIndex) BOOL showTableIndex;           // Defaults to NO
@property (nonatomic, assign, getter = shouldShowSectionHeaders) BOOL showSectionHeaders;   // Defaults to NO, Overridden if the delegate implements tableView:titleForHeaderInSection:

- (id)initWithTableView:(UITableView*)tableView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListDataSourceDelegate>)delegate;  // Calls beginObservingList before returning

// Begin/End CollectionList Observing
- (void)beginObservingList;     // Adds self as an observer of collectionList - Create a retain cycle
- (void)endObservingList;       // Removes self as an observer of collectionList - Breaks the retain cycle

@end
