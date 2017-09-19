//
//  TCTestCase.m
//  Tayphoon
//
//  Created by Tayphoon on 31/07/2017.
//  Copyright © 2017 Tayphoon. All rights reserved.
//

#import "TCTestCase.h"

@implementation TCTestCase

- (void)setupInMemoryCoreDataStackWithStoreFileName:(NSString*)storeFileName
                                    concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
                                              error:(NSError**)error {
    NSBundle * mainBundle = [NSBundle bundleWithIdentifier:@"ru.tayphoon.MultiFetchedResultsTests"];
    NSString * modelPath = [mainBundle pathForResource:storeFileName ofType:@"momd"];
    NSURL * modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] mutableCopy];
    
    // Coordinator with in-mem store type
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:error];
    
    // Context with private queue
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
    context.persistentStoreCoordinator = coordinator;
    _managedObjectContext = context;
}

- (void)cleanUpCoreDataStack {
    if (self.managedObjectContext) {
        NSError * error;
        
        [self.managedObjectContext performBlockAndWait:^{
            [self.managedObjectContext reset];
        }];
        
        for (NSPersistentStore * persistentStore in self.managedObjectContext.persistentStoreCoordinator.persistentStores) {
            
            BOOL success = [self.managedObjectContext.persistentStoreCoordinator removePersistentStore:persistentStore error:&error];
            if (!success) {
                NSLog(@"Failed clean up persistent store with error: %@", error);
            }
        }
        
        _managedObjectContext = nil;
    }
}

@end
