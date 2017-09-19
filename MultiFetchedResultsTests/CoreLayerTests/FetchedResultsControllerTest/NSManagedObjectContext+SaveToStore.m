//
//  NSManagedObjectContext+SaveToStore.m
//  Tayphoon
//
//  Created by Tayphoon on 22.08.17.
//  Copyright © 2017 Tayphoon. All rights reserved.
//

#import "NSManagedObjectContext+SaveToStore.h"

@implementation NSManagedObjectContext (SaveToStore)

- (BOOL)saveToPersistentStore:(NSError**)error {
    __block NSError *localError = nil;
    NSManagedObjectContext *contextToSave = self;
    while (contextToSave) {
        __block BOOL success;
        
        /**
         To work around issues in ios 5 first obtain permanent object ids for any inserted objects.  If we don't do this then its easy to get an `NSObjectInaccessibleException`.  This happens when:
         
         1. Create new object on main context and save it.
         2. At this point you may or may not call obtainPermanentIDsForObjects for the object, it doesn't matter
         3. Update the object in a private child context.
         4. Save the child context to the parent context (the main one) which will work,
         5. Save the main context - a NSObjectInaccessibleException will occur and Core Data will either crash your app or lock it up (a semaphore is not correctly released on the first error so the next fetch request will block forever.
         */
        __block BOOL obtained;
        [contextToSave performBlockAndWait:^{
            obtained = [contextToSave obtainPermanentIDsForObjects:[[contextToSave insertedObjects] allObjects] error:&localError];
        }];
        if (!obtained) {
            if (error) *error = localError;
            return NO;
        }
        
        [contextToSave performBlockAndWait:^{
            success = [contextToSave save:&localError];
            if (! success && localError == nil) NSLog(@"Saving of managed object context failed, but a `nil` value for the `error` argument was returned. This typically indicates an invalid implementation of a key-value validation method exists within your model. This violation of the API contract may result in the save operation being mis-interpretted by callers that rely on the availability of the error.");
        }];
        
        if (! success) {
            if (error) *error = localError;
            return NO;
        }
        
        if (! contextToSave.parentContext && contextToSave.persistentStoreCoordinator == nil) {
            NSLog(@"Reached the end of the chain of nested managed object contexts without encountering a persistent store coordinator. Objects are not fully persisted.");
            return NO;
        }
        contextToSave = contextToSave.parentContext;
    }
    
    return YES;
}

@end
