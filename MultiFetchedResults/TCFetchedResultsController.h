//
//  TCFetchedResultsController.h
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


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN
@protocol TCFetchedResultsControllerDelegate;

/**
 You use a fetched results controller to efficiently manage the results returned from a Core Data fetch requests to 
 provide data for a UITableView object.
 In addition, fetched results controllers provide the following features:
 Optionally monitor changes to objects in the associated managed object context, and report changes in the results set to
 its delegate (see The Controller’s Delegate).
 No tracking: the delegate is set to nil.
 The controller simply provides access to the data as it was when the fetch was executed.
 Full persistent tracking: the delegate and the file cache name are non-nil.
 The controller monitors objects in its result set and updates ordering information in response to relevant changes.
 Important
 A delegate must implement at least one of the change tracking delegate methods in order for change tracking to be enabled.
 Providing an empty implementation of controllerDidChangeContent: is sufficient.
 */
@interface TCFetchedResultsController : NSObject

/**
 @abstract An array containing a NSFetchRequest instance used to do the fetching. You must not change it, its predicate,
 or its sort descriptor after initialization.
 */
@property (nonatomic, readonly) NSArray<NSFetchRequest*> * fetchRequests;
/**
 @abstract Managed Object Context used to fetch objects. The controller registers to listen to change notifications on 
 this context and properly update its result set and section information.
 */
@property (nonatomic, readonly) NSManagedObjectContext * managedObjectContext;
/**
 @abstract An array containing a NSSortDescriptor instance used to do the sorting after fetching. You must not change it
 after initialization.
 */
@property (nullable, nonatomic, strong) NSArray<NSSortDescriptor*> * sortDescriptors;
/**
 @abstract Returns the results of the fetch.
 Returns nil if the performFetch: hasn't been called.
 */
@property (nullable, nonatomic, readonly) NSArray * fetchedObjects;

/**
 @abstract Delegate that is notified when the result set changes.
 */
@property(nullable, nonatomic, assign) id<TCFetchedResultsControllerDelegate> delegate;

- (instancetype)initWithFetchRequest:(NSArray<NSFetchRequest*>*)fetchRequests
                managedObjectContext:(NSManagedObjectContext*)context
                     sortDescriptors:(nullable NSArray<NSSortDescriptor*>*)sortDescriptors NS_DESIGNATED_INITIALIZER;

/**
 @abstract Executes the fetch request on the store to get objects.
 Returns YES if successful or NO (and an error) if a problem occurred.
 An error is returned if the fetch request specified doesn't include a sort descriptors.
 After executing this method, the fetched objects can be accessed with the property 'fetchedObjects'
 */
- (BOOL)performFetch:(NSError **)error;

/**
 @abstract Returns the indexPath of a given object.
 */
- (nullable NSIndexPath*)indexPathForObject:(id)object;

@end

/**
 @abstract The `TCFetchedResultsControllerDelegate` protocol provides a method for notifying delegate about fetched objects changes.
 */
@protocol TCFetchedResultsControllerDelegate <NSObject>

typedef NS_ENUM(NSUInteger, TCFetchedResultsChangeType) {
    TCFetchedResultsChangeInsert = 1,
    TCFetchedResultsChangeDelete = 2,
    TCFetchedResultsChangeMove = 3,
    TCFetchedResultsChangeUpdate = 4
};

@optional

/**
 @abstract Notifies the delegate that section and object changes are about to be processed and notifications will be sent.
 Enables NSFetchedResultsController change tracking. Clients may prepare for a batch of updates by using this method 
 to begin an update block for their view.
 */
- (void)controllerWillChangeContent:(TCFetchedResultsController*)controller;

/**
 @abstract Notifies the delegate that a fetched object has been changed due to an add, remove, move, or update. Enables NSFetchedResultsController change tracking.
	controller - controller instance that noticed the change on its fetched objects
	anObject - changed object
	indexPath - indexPath of changed object (nil for inserts)
	type - indicates if the change was an insert, delete, move, or update
	newIndexPath - the destination path of changed object (nil for deletes)
	
	Changes are reported with the following heuristics:
 
	Inserts and Deletes are reported when an object is created, destroyed, or changed in such a way that changes whether it matches the fetch request's predicate. Only the Inserted/Deleted object is reported; like inserting/deleting from an array, it's assumed that all objects that come after the affected object shift appropriately.
	Move is reported when an object changes in a manner that affects its position in the results.  An update of the object is assumed in this case, no separate update message is sent to the delegate.
	Update is reported when an object's state changes, and the changes do not affect the object's position in the results.
 */
- (void)controller:(TCFetchedResultsController*)controller
   didChangeObject:(id)anObject
       atIndexPath:(nullable NSIndexPath*)indexPath
     forChangeType:(TCFetchedResultsChangeType)type
      newIndexPath:(nullable NSIndexPath*)newIndexPath;

/**
 @abstract Notifies the delegate that all section and object changes have been sent. Enables NSFetchedResultsController change tracking.
 Clients may prepare for a batch of updates by using this method to begin an update block for their view.
 Providing an empty implementation will enable change tracking if you do not care about the individual callbacks.
 */
- (void)controllerDidChangeContent:(TCFetchedResultsController*)controller;

@end

NS_ASSUME_NONNULL_END
