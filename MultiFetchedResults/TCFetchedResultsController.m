//
//  TCFetchedResultsController.m
//  Tayphoon
//
//  Created by Tayphoon on 27.07.17.
//  Copyright © 2017 Tayphoon. All rights reserved.
//

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TCFetchedResultsController.h"
#import "NSManagedObjectContext+Async.h"

@interface TCFetchedResultsController()

@property (nonatomic, strong) NSArray<NSPredicate*> * filterPredicates;
@property (nullable, nonatomic, readwrite) NSArray * fetchedObjects;

@end

@implementation TCFetchedResultsController

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-init is not a valid initializer for the class %@, use designated initilizer -initWithFetchRequest:managedObjectContext:", NSStringFromClass([self class])]
                                 userInfo:nil];
    return [self init];
}

- (instancetype)initWithFetchRequest:(NSArray<NSFetchRequest*>*)fetchRequests
                managedObjectContext:(NSManagedObjectContext*)context
                     sortDescriptors:(NSArray<NSSortDescriptor*>*)sortDescriptors {
    self = [super init];
    
    if (self) {
        NSParameterAssert(context);
        NSParameterAssert(fetchRequests);
        _managedObjectContext = context;
        _fetchRequests = fetchRequests;
        _sortDescriptors = sortDescriptors;
        self.filterPredicates = [self filterPredicatesForRequests:self.fetchRequests];
    }
    
    return self;
}

- (BOOL)performFetch:(NSError **)error {
    NSError * fetchError;
    self.fetchedObjects = [self executeFetchRequests:self.fetchRequests
                                managedObjectContext:self.managedObjectContext
                                               error:&fetchError];
    
    if (error) {
        *error = fetchError;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextObjectsDidChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.managedObjectContext];
    
    return (fetchError == nil);
}

- (nullable NSIndexPath*)indexPathForObject:(id)object {
    NSInteger index = [self.fetchedObjects indexOfObject:object];
    
    if (index != NSNotFound) {
        return [NSIndexPath indexPathForRow:index inSection:0];
    }
    
    return nil;
}

#pragma mark - NSManagedObjectContextObjectsDidChangeNotification

- (void)managedObjectContextObjectsDidChange:(NSNotification*)notification {
    NSDictionary * userInfo = notification.userInfo;
    NSSet * insertedObjects = userInfo[NSInsertedObjectsKey];
    NSSet * updatedObjects = userInfo[NSUpdatedObjectsKey];
    NSSet * deletedObjects = userInfo[NSDeletedObjectsKey];

    __block BOOL shouldProcessUpdates = NO;
    __block NSMutableSet * updatesToProcess = [NSMutableSet set];
    [self.filterPredicates enumerateObjectsUsingBlock:^(NSPredicate * predicate, NSUInteger idx, BOOL * stop) {
        NSSet * filteredObjects = [insertedObjects filteredSetUsingPredicate:predicate];
        shouldProcessUpdates |= ([filteredObjects count] > 0);

        filteredObjects = [updatedObjects filteredSetUsingPredicate:predicate];
        [updatesToProcess addObjectsFromArray:[filteredObjects allObjects]];
        
        filteredObjects = [deletedObjects filteredSetUsingPredicate:predicate];
        shouldProcessUpdates |= ([filteredObjects count] > 0);
    }];
    
    if ([updatesToProcess count] > 0 || shouldProcessUpdates) {
        __weak typeof(self) weakSelf = self;
        [self.managedObjectContext performBlockInBackground:^(NSManagedObjectContext * backgroundContext) {
            NSArray * previousObjects = [backgroundContext objectsFromOtherContext:weakSelf.fetchedObjects];
            NSArray * objectsToUpdate = [backgroundContext objectsFromOtherContext:[updatesToProcess allObjects]];
            
            NSError * fetchError;
            NSArray * fetchedObjects = [weakSelf executeFetchRequests:weakSelf.fetchRequests managedObjectContext:backgroundContext error:&fetchError];
            NSMutableArray * insertedObjects = [NSMutableArray arrayWithArray:fetchedObjects];
            [insertedObjects removeObjectsInArray:previousObjects];
            
            NSMutableArray * deletedObjects = [NSMutableArray arrayWithArray:previousObjects];
            [deletedObjects removeObjectsInArray:fetchedObjects];
            
            weakSelf.fetchedObjects = [weakSelf.managedObjectContext objectsFromOtherContext:fetchedObjects];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf notifyControllerWillChangeContent];
                
                [insertedObjects enumerateObjectsUsingBlock:^(NSManagedObject * managedObject, NSUInteger idx, BOOL * stop) {
                    NSUInteger index = [fetchedObjects indexOfObject:managedObject];
                    if (index != NSNotFound) {
                        [weakSelf notifyControllerDidChangeObject:[weakSelf.managedObjectContext objectWithID:managedObject.objectID]
                                                      atIndexPath:nil
                                                    forChangeType:TCFetchedResultsChangeInsert
                                                     newIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                    }
                }];
                
                [deletedObjects enumerateObjectsUsingBlock:^(NSManagedObject * managedObject, NSUInteger idx, BOOL * stop) {
                    NSUInteger index = [previousObjects indexOfObject:managedObject];
                    if (index != NSNotFound) {
                        [weakSelf notifyControllerDidChangeObject:[weakSelf.managedObjectContext objectWithID:managedObject.objectID]
                                                      atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
                                                    forChangeType:TCFetchedResultsChangeDelete
                                                     newIndexPath:nil];
                    }
                }];
                
                [objectsToUpdate enumerateObjectsUsingBlock:^(NSManagedObject * managedObject, NSUInteger idx, BOOL * stop) {
                    NSUInteger previousIndex = [previousObjects indexOfObject:managedObject];
                    NSUInteger newIndex = [fetchedObjects indexOfObject:managedObject];
                   if (previousIndex != NSNotFound) {
                       NSIndexPath * indexPath = (previousIndex != NSNotFound) ? [NSIndexPath indexPathForRow:previousIndex inSection:0] : nil;
                       NSIndexPath * newIndexPath = (newIndex != NSNotFound && previousIndex != newIndex) ? [NSIndexPath indexPathForRow:newIndex inSection:0] : nil;
                        [weakSelf notifyControllerDidChangeObject:[weakSelf.managedObjectContext objectWithID:managedObject.objectID]
                                                      atIndexPath:indexPath
                                                    forChangeType:(previousIndex == newIndex) ? TCFetchedResultsChangeUpdate : TCFetchedResultsChangeMove
                                                     newIndexPath:newIndexPath];
                    }
                }];
                
                [weakSelf notifyControllerDidChangeContent];
            });
        }];
    }
}

#pragma mark - Private methods

- (nullable NSArray *)executeFetchRequests:(NSArray<NSFetchRequest*>*)fetchRequests
                      managedObjectContext:(NSManagedObjectContext*)managedObjectContext
                                     error:(NSError **)error {
    __block NSMutableArray * fetchedObjects = [NSMutableArray array];
    [fetchRequests enumerateObjectsUsingBlock:^(NSFetchRequest * fetchRequest, NSUInteger idx, BOOL * stop) {
        NSError * fetchError;
        NSArray * fetchResults = [managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
        
        if (!fetchError) {
            [fetchedObjects addObjectsFromArray:fetchResults];
        }
        else {
            if (error) {
                *error = fetchError;
                [fetchedObjects removeAllObjects];
                *stop = YES;
            }
        }
    }];
    
    if (self.sortDescriptors) {
        [fetchedObjects sortUsingDescriptors:self.sortDescriptors];
    }
    
    return [fetchedObjects copy];
}

- (NSArray<NSPredicate*>*)filterPredicatesForRequests:(NSArray<NSFetchRequest*>*)fetchRequests {
    __block NSMutableArray * predicates = [NSMutableArray array];
    [fetchRequests enumerateObjectsUsingBlock:^(NSFetchRequest * fetchRequest, NSUInteger idx, BOOL * stop) {
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"entity.name == %@", fetchRequest.entityName];
        if (fetchRequest.predicate) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, fetchRequest.predicate]];
        }
        
        [predicates addObject:predicate];
    }];

    return [predicates copy];
}

- (void)notifyControllerWillChangeContent {
    if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)]) {
        [self.delegate controllerWillChangeContent:self];
    }
}

- (void)notifyControllerDidChangeObject:(id)object
                            atIndexPath:(NSIndexPath*)indexPath
                          forChangeType:(TCFetchedResultsChangeType)type
                           newIndexPath:(NSIndexPath*)newIndexPath {
    if ([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
        [self.delegate controller:self
                  didChangeObject:object
                      atIndexPath:indexPath
                    forChangeType:type
                     newIndexPath:newIndexPath];
    }
}

- (void)notifyControllerDidChangeContent {
    if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
        [self.delegate controllerDidChangeContent:self];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
