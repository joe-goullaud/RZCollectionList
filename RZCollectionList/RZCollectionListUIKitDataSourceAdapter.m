//
//  RZCollectionListUIKitDataSourceAdapter.m
//  bhphoto
//
//  Created by Nick Donaldson on 3/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListUIKitDataSourceAdapter.h"
#import "RZObserverCollection.h"

// Uncomment to enable debug log messages
#define RZCL_SWZ_DEBUG

// ================================================================================================

@interface RZCollectionListSwizzledObjectNotification : NSObject

@property (nonatomic, weak)   id changedObject;

@property (nonatomic, assign) RZCollectionListChangeType changeType;
@property (nonatomic, strong) NSIndexPath *originalIndexPath;
@property (nonatomic, strong) NSIndexPath *originalNewIndexPath;
@property (nonatomic, strong) NSIndexPath *swizzledIndexPath;
@property (nonatomic, strong) NSIndexPath *swizzledNewIndexPath;

- (id)initWithChangeType:(RZCollectionListChangeType)changeType object:(id)object indexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath;
- (void)adjustSectionIndicesBy:(NSInteger)sectionAdjustment rowIndicesBy:(NSInteger)rowAdjustment;

#ifdef RZCL_SWZ_DEBUG
- (void)logNotificationForward;
#endif

@end

@implementation RZCollectionListSwizzledObjectNotification

- (id)initWithChangeType:(RZCollectionListChangeType)changeType object:(id)object indexPath:(NSIndexPath *)indexPath newIndexPath:(NSIndexPath *)newIndexPath
{
    self = [super init];
    if (self) {
        self.changeType = changeType;
        self.originalIndexPath = self.swizzledIndexPath = indexPath;
        self.originalNewIndexPath = self.swizzledNewIndexPath = newIndexPath;
    }
    return self;
}

- (void)adjustSectionIndicesBy:(NSInteger)sectionAdjustment rowIndicesBy:(NSInteger)rowAdjustment
{
    self.swizzledIndexPath = [NSIndexPath indexPathForRow:self.swizzledIndexPath.row + rowAdjustment inSection:self.swizzledIndexPath.section + sectionAdjustment];
    self.swizzledNewIndexPath = [NSIndexPath indexPathForRow:self.swizzledNewIndexPath.row + rowAdjustment inSection:self.swizzledNewIndexPath.section + sectionAdjustment];
}

#ifdef RZCL_SWZ_DEBUG
- (void)logNotificationForward
{
    if (self.changeType == RZCollectionListChangeDelete){
        NSLog(@"Sending deletion notification at [%d, %d]", self.swizzledIndexPath.section, self.swizzledIndexPath.row);
    }
    else if (self.changeType == RZCollectionListChangeInsert){
        NSLog(@"Sending insertion notification at [%d, %d]", self.swizzledNewIndexPath.section, self.swizzledNewIndexPath.row);
    }
    else if (self.changeType == RZCollectionListChangeMove){
        NSLog(@"Sending move notification from [%d, %d] to [%d, %d]", self.swizzledIndexPath.section, self.swizzledIndexPath.row, self.swizzledNewIndexPath.section, self.swizzledNewIndexPath.row);
    }
    else if (self.changeType == RZCollectionListChangeUpdate){
        NSLog(@"Sending update notification at [%d, %d]", self.swizzledIndexPath.section, self.swizzledIndexPath.row);
    }
}
#endif

@end

// ================================================================================================

@interface RZCollectionListSwizzledSectionNotification : NSObject

@property (nonatomic, weak)     id<RZCollectionListSectionInfo> sectionInfo;
@property (nonatomic, assign)   RZCollectionListChangeType changeType;
@property (nonatomic, assign)   NSInteger originalIndex;
@property (nonatomic, assign)   NSInteger swizzledIndex;

- (id)initWithChangeType:(RZCollectionListChangeType)changeType sectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSInteger)sectionIndex;

#ifdef RZCL_SWZ_DEBUG
- (void)logNotificationForward;
#endif

@end

@implementation RZCollectionListSwizzledSectionNotification

-(id)initWithChangeType:(RZCollectionListChangeType)changeType sectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSInteger)sectionIndex
{
    self = [super init];
    if (self) {
        self.sectionInfo = sectionInfo;
        self.changeType = changeType;
        self.originalIndex = self.swizzledIndex = sectionIndex;
    }
    return self;
}

#ifdef RZCL_SWZ_DEBUG
- (void)logNotificationForward
{
    if (self.changeType == RZCollectionListChangeDelete){
        NSLog(@"Sending section deletion notification at %d", self.swizzledIndex);
    }
    else if (self.changeType == RZCollectionListChangeInsert){
        NSLog(@"Sending section insertion notification at %d", self.swizzledIndex);
    }
    else if (self.changeType == RZCollectionListChangeMove){
        NSLog(@"Sending section move notification at %d", self.swizzledIndex); // can this happen?
    }
    else if (self.changeType == RZCollectionListChangeUpdate){
        NSLog(@"Sending section update notification at %d", self.swizzledIndex);
    }
}
#endif

@end

// ================================================================================================

@interface RZCollectionListUIKitDataSourceAdapter ()

@property (nonatomic, strong) RZObserverCollection *observerCollection;
@property (nonatomic, strong) NSMutableArray *swizzledObjectNotifications;
@property (nonatomic, strong) NSMutableArray *swizzledSectionNotifications;
@property (nonatomic, weak)   id<RZCollectionList> sourceList;

@property (nonatomic, assign) BOOL isUpdating;

- (void)commonInit;
- (void)forwardObjectUpdateNotifications;

@end

@implementation RZCollectionListUIKitDataSourceAdapter

- (id)init{
    self = [super init];
    if (self){
        [self commonInit];
    }
    return self;
}

- (id)initWithObserver:(id<RZCollectionListObserver>)observer
{
    self = [super init];
    if (self) {
        [self commonInit];
        [self.observerCollection addObject:observer];
    }
    return self;
}

- (void)commonInit
{
    self.observerCollection = [[RZObserverCollection alloc] init];
    self.swizzledObjectNotifications = [NSMutableArray arrayWithCapacity:32];
    self.swizzledSectionNotifications = [NSMutableArray arrayWithCapacity:8];
}

- (void)addObserver:(id<RZCollectionListObserver>)observer
{
    [self.observerCollection addObject:observer];
}

- (void)removeObserver:(id<RZCollectionListObserver>)observer
{
    [self.observerCollection removeObject:observer];
}

- (void)forwardObjectUpdateNotifications
{
    // TODO: May need to re-order these
    [self.swizzledSectionNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        RZCollectionListSwizzledSectionNotification *swizzledNotification = obj;
        
#ifdef RZCL_SWZ_DEBUG
        [swizzledNotification logNotificationForward];
#endif
        
        [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj collectionList:self.sourceList
               didChangeSection:swizzledNotification.sectionInfo
                        atIndex:swizzledNotification.swizzledIndex
                  forChangeType:swizzledNotification.changeType];
        }];
        
    }];
    
    
    [self.swizzledObjectNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        RZCollectionListSwizzledObjectNotification *swizzledNotification = obj;
        
#ifdef RZCL_SWZ_DEBUG
        [swizzledNotification logNotificationForward];
#endif
        
        [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj collectionList:self.sourceList
                didChangeObject:swizzledNotification.changedObject
                    atIndexPath:swizzledNotification.swizzledIndexPath
                  forChangeType:swizzledNotification.changeType
                   newIndexPath:swizzledNotification.swizzledNewIndexPath];
        }];
        
    }];
    
}

#pragma mark - RZCollectionListObserver

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
 
    RZCollectionListSwizzledObjectNotification *swizzledNotification = [[RZCollectionListSwizzledObjectNotification alloc] initWithChangeType:type object:object indexPath:indexPath newIndexPath:newIndexPath];
    
    // Delete
    if (type == RZCollectionListChangeDelete){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object removal at [%d, %d]", indexPath.section, indexPath.row);
#endif
        
        __block NSInteger rowAdjustment = 0;
        [self.swizzledObjectNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
           
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;
            if (otherNotification.originalIndexPath.section == indexPath.section)
            {
                if (otherNotification.changeType == RZCollectionListChangeDelete && otherNotification.originalIndexPath.row <= indexPath.row){
                    rowAdjustment++;
                }
                else if (otherNotification.changeType == RZCollectionListChangeInsert && indexPath.row < otherNotification.originalIndexPath.row){
                    [otherNotification adjustSectionIndicesBy:0 rowIndicesBy:-1];
                }
            }
            
        }];
        
        [swizzledNotification adjustSectionIndicesBy:0 rowIndicesBy:rowAdjustment];
        
    }
    // Insert
    else if (type == RZCollectionListChangeInsert){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object insertion at [%d, %d]", newIndexPath.section, newIndexPath.row);
#endif
        __block NSInteger rowAdjustment = 0;
        [self.swizzledObjectNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;
            if (otherNotification.originalIndexPath.section == indexPath.section)
            {
                if (otherNotification.changeType == RZCollectionListChangeDelete){
                    
                }
                else if (otherNotification.changeType == RZCollectionListChangeInsert){
                    
                }
            }
            
        }];
        
        [swizzledNotification adjustSectionIndicesBy:0 rowIndicesBy:rowAdjustment];
    }
    // Move
    else if (type == RZCollectionListChangeMove){
        
        // TODO: Need to know if these happen before or after removals (assuming after)
        
        
        
    }
    // Update
    else if (type == RZCollectionListChangeUpdate){
        
                
        
    }
    
    [self.swizzledObjectNotifications addObject:swizzledNotification];
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    RZCollectionListSwizzledSectionNotification *swizzledNotification = [[RZCollectionListSwizzledSectionNotification alloc] initWithChangeType:type
                                                                                                                                   sectionInfo:sectionInfo
                                                                                                                                  sectionIndex:sectionIndex];
    
    // Delete
    if (type == RZCollectionListChangeDelete){
    
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Section removal at %d", sectionIndex);
#endif
        
    }
    // Insert
    else if (type == RZCollectionListChangeInsert){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Section insertion at %d", sectionIndex);
#endif
        
    }
    // Move
    else if (type == RZCollectionListChangeMove){
        
        // TODO: Need to know if these happen before or after removals (assuming after)
        
        
        
        
    }
    // Update
    else if (type == RZCollectionListChangeUpdate){
        
        
        
        
        
    }

    
    [self.swizzledSectionNotifications addObject:swizzledNotification];
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    self.sourceList = collectionList;
    self.isUpdating = YES;
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionListWillChangeContent:collectionList];
    }];
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.isUpdating){
        [self forwardObjectUpdateNotifications];
        [self.swizzledObjectNotifications removeAllObjects];
        [self.swizzledSectionNotifications removeAllObjects];
        self.isUpdating = NO;
        self.sourceList = nil;
    }
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionListDidChangeContent:collectionList];
    }];
}

@end

