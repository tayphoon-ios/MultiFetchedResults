//
//  NSManagedObjectContext+Async.h
//  Tayphoon
//
//  Created by Tayphoon on 12.09.13.
//  Copyright (c) 2013 Tayphoon. All rights reserved.
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

#import <CoreData/CoreData.h>

/**
 @abstract The category of `NSManagedObjectContext` to improve work with asynchronously tasks.
 */
@interface NSManagedObjectContext (Async)
/**
 @abstract Executes the fetch request on the store to get objects in background thread.
 @param completion The block returns fetched objects in main thread or error if fetch failed.
*/
- (void)executeFetchRequest:(NSFetchRequest*)request completion:(void (^)(NSArray * objects, NSError * error))completion;
/**
 @abstract Executes the fetch request on the store to delete objects in background thread.
 @param completion The block returns error if fetching or deleting failed.
 */
- (void)deleteAllObjectsForEntety:(NSString*)entityName completion:(void (^)(NSError * error))completion;
/**
 @abstract Executes block asynchronously in background thread.
 @param block The block returns `NSManagedObjectContext` for background thread.
 */
- (void)performBlockInBackground:(void (^)(NSManagedObjectContext * backgroundContext))block;
/**
 @abstract Executes block synchronously in background thread.
 @param block The block returns `NSManagedObjectContext` for background thread.
 */
- (void)performBlockAndWaitInBackground:(void (^)(NSManagedObjectContext * backgroundContext))block;
/**
 @abstract Obtains managed objects synchronously from other context by objectID.
 @param objects Managed objects from other context.
 */
- (NSArray*)objectsFromOtherContext:(NSArray<NSManagedObject*>*)objects;
/**
 @abstract Obtains managed objects asynchronously from other context by objectID.
 @param completion The block returns managed objects from other context.
 */
- (void)objectsFromOtherContext:(NSArray*)objects completion:(void (^)(NSArray * objects))completion;

@end
