//
//  NSManagedObjectContext+Async.m
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

#import "NSManagedObjectContext+Async.h"

@implementation NSManagedObjectContext (Async)

- (void)executeFetchRequest:(NSFetchRequest *)request completion:(void (^)(NSArray *objects, NSError *error))completion {
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    
    NSManagedObjectContext * backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [backgroundContext performBlock:^{
        backgroundContext.persistentStoreCoordinator = coordinator;
        
        // Fetch into shared persistent store in background thread
        NSError * error = nil;
        NSArray * fetchedObjects = [backgroundContext executeFetchRequest:request error:&error];
        if(request.resultType == NSManagedObjectResultType) {
            [self performBlock:^{
                if (fetchedObjects) {
                    // Collect object IDs
                    NSArray * objectIds = [fetchedObjects valueForKey:@"objectID"];
                    
                    // Fault in objects into current context by object ID as they are available in the shared persistent store
                    NSMutableArray * mutObjects = [[NSMutableArray alloc] initWithCapacity:[objectIds count]];
                    for (NSManagedObjectID * objectID in objectIds) {
                        NSManagedObject * obj = [self objectWithID:objectID];
                        [mutObjects addObject:obj];
                    }
                    
                    if (completion) {
                        NSArray *objects = [mutObjects copy];
                        completion(objects, nil);
                    }
                } else {
                    if (completion) {
                        completion(nil, error);
                    }
                }
            }];
        }
        else {
            if (!error && completion) {
                completion(fetchedObjects, nil);
                
            } if (completion) {
                completion(nil, error);
            }
        }
    }];
}

- (void)deleteAllObjectsForEntety:(NSString*)entityName completion:(void (^)(NSError *error))completion {
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSManagedObjectContext * backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = self;
    [backgroundContext performBlock:^{        
        // Fetch into shared persistent store in background thread
        NSError * error = nil;
        NSArray * fetchedObjects = [backgroundContext executeFetchRequest:request error:&error];
        // Remove all fetched objects
        for (NSManagedObject * managedObject in fetchedObjects) {
            [backgroundContext deleteObject:managedObject];
        }
        
        NSError * saveError = nil;
        [backgroundContext save:&saveError];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completion) {
                completion(saveError);
            }
        });
    }];
}

- (void)performBlockInBackground:(void (^)(NSManagedObjectContext * backgroundContext))block {
    if (block) {
        NSManagedObjectContext * backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        backgroundContext.parentContext = self;
        [backgroundContext performBlock:^{
            block(backgroundContext);
        }];
    }
}

- (void)performBlockAndWaitInBackground:(void (^)(NSManagedObjectContext * backgroundContext))block {
    if (block) {
        NSManagedObjectContext * backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        backgroundContext.parentContext = self;
        [backgroundContext performBlockAndWait:^{
            block(backgroundContext);
        }];
    }
}

- (NSArray*)objectsFromOtherContext:(NSArray<NSManagedObject*>*)objects {
    // Collect object IDs
    NSArray * objectIds = [objects valueForKey:@"objectID"];
    
    // Fault in objects into current context by object ID as they are available in the shared persistent store
    NSMutableArray * mutObjects = [[NSMutableArray alloc] initWithCapacity:[objectIds count]];
    for (NSManagedObjectID * objectID in objectIds) {
        NSManagedObject * obj = [self objectWithID:objectID];
        [mutObjects addObject:obj];
    }
    return [mutObjects copy];
}

- (void)objectsFromOtherContext:(NSArray *)objects completion:(void (^)(NSArray * objects))completion {
    [self performBlock:^{
        if (objects) {
            // Collect object IDs
            NSArray * objectsInContext = [self objectsFromOtherContext:objects];
            if (completion) {
                completion(objectsInContext);
            }
        }
        else if (completion) {
            completion(nil);
        }
    }];
}

@end
