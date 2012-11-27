//
//  FilteredListViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/20/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "FilteredListViewController.h"
#import "RZArrayCollectionList.h"
#import "RZFilteredCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"
#import "ListItemObject.h"

@interface FilteredListViewController () <RZCollectionListDataSourceDelegate>

@property (nonatomic, strong) RZFilteredCollectionList *filteredList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *listDataSource;

- (NSArray*)listItemObjects;

- (void)keyboardWillShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;

@end

@implementation FilteredListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    RZArrayCollectionList *arrayList = [[RZArrayCollectionList alloc] initWithArray:[self listItemObjects] sectionNameKeyPath:@"subtitle"];
    self.filteredList = [[RZFilteredCollectionList alloc] initWithSourceList:arrayList predicate:nil];
    self.listDataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:self.filteredList delegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (NSArray*)listItemObjects
{
    return @[
    [ListItemObject listItemObjectWithName:@"Item 0" subtitle:@"1 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 1" subtitle:@"1 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 2" subtitle:@"1 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 3" subtitle:@"1 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 4" subtitle:@"1 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 5" subtitle:@"1 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 6" subtitle:@"2 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 7" subtitle:@"2 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 8" subtitle:@"2 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 9" subtitle:@"2 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 10" subtitle:@"2 Subtitle"],
    [ListItemObject listItemObjectWithName:@"Item 11" subtitle:@"2 Subtitle"]
    ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - RZCollectionListDataSourceDelegate

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"FilteredCellIdentifier";
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    ListItemObject *item = (ListItemObject*)object;
    
    if ([item isKindOfClass:[ListItemObject class]])
    {
        cell.textLabel.text = item.itemName;
        cell.detailTextLabel.text = item.subtitle;
    }
    
    return cell;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSPredicate * predicate = nil;
    
    if (searchText && [searchText length] > 0)
    {
        predicate = [NSPredicate predicateWithFormat:@"itemName CONTAINS %@", searchText];
    }
    
    self.filteredList.predicate = predicate;
}

#pragma mark - UIKeyboard Notification Callbacks

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSTimeInterval keyboardAnimTime = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardAnimCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.tableViewBottomSpaceConstraint.constant = -keyboardFrame.size.height;
    
    [UIView animateWithDuration:keyboardAnimTime delay:0 options:keyboardAnimCurve animations:^{
        [self.view layoutIfNeeded];
    } completion:NULL];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    NSTimeInterval keyboardAnimTime = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardAnimCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    self.tableViewBottomSpaceConstraint.constant = 0;
    
    [UIView animateWithDuration:keyboardAnimTime delay:0 options:keyboardAnimCurve animations:^{
        [self.view layoutIfNeeded];
    } completion:NULL];
}

@end