//
//  TCFetchedResultsControllerTest.m
//  Tayphoon
//
//  Created by Tayphoon on 28.07.17.
//  Copyright © 2017 Tayphoon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>

#import "TCTestEnvironment.h"
#import "TCFetchedResultsController.h"
#import "NSManagedObjectContext+Async.h"
#import "NSManagedObjectContext+SaveToStore.h"
#import "CSPeople.h"
#import "CSAnimal.h"

@interface TCFetchedResultsControllerTest : TCTestCase <TCFetchedResultsControllerDelegate>

@property (nonatomic, strong) TCFetchedResultsController * fetchedResultsController;

@property (nonatomic, strong) NSMutableSet * insertedObjects;
@property (nonatomic, strong) NSMutableSet * updatedObjects;
@property (nonatomic, strong) NSMutableSet * movedObjects;
@property (nonatomic, strong) NSMutableSet * deletedObjects;

@end

@implementation TCFetchedResultsControllerTest

- (void)setUp {
    [super setUp];
    
    NSError * setupError;
    [self setupInMemoryCoreDataStackWithStoreFileName:@"DataModel"
                                      concurrencyType:NSMainQueueConcurrencyType
                                                error:&setupError];
    expect(setupError).to.beNil();

    NSFetchRequest * peoplesRequest = [NSFetchRequest fetchRequestWithEntityName:@"People"];
    NSFetchRequest * animalsRequest = [NSFetchRequest fetchRequestWithEntityName:@"Animal"];

    NSArray * sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]];
    self.fetchedResultsController = [[TCFetchedResultsController alloc] initWithFetchRequest:@[peoplesRequest, animalsRequest]
                                                                        managedObjectContext:self.managedObjectContext
                                                                             sortDescriptors:sortDescriptors];
    
    self.fetchedResultsController.delegate = self;
}

- (void)tearDown {
    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;

    [self.insertedObjects removeAllObjects];
    [self.updatedObjects removeAllObjects];
    [self.movedObjects removeAllObjects];
    [self.deletedObjects removeAllObjects];
    
    [self cleanUpCoreDataStack];
    [super tearDown];
}

- (void)testPerformObjects {
    [NSEntityDescription insertNewObjectForEntityForName:@"People" inManagedObjectContext:self.managedObjectContext];
    [NSEntityDescription insertNewObjectForEntityForName:@"Animal" inManagedObjectContext:self.managedObjectContext];

    NSError * error;
    [self.managedObjectContext save:&error];
    expect(error).to.beNil();

    NSError * fetchError;
    [self.fetchedResultsController performFetch:&fetchError];
    expect(fetchError).to.beNil();
    expect([self.fetchedResultsController.fetchedObjects count]).will.equal(2);
}

- (void)testRandomUpdates {
    CSPeople * people1 = [NSEntityDescription insertNewObjectForEntityForName:@"People" inManagedObjectContext:self.managedObjectContext];
    people1.sortOrder = @(0);
    CSPeople * people2 = [NSEntityDescription insertNewObjectForEntityForName:@"People" inManagedObjectContext:self.managedObjectContext];
    people2.sortOrder = @(1);

    NSError * error;
    [self.managedObjectContext save:&error];
    expect(error).to.beNil();
    
    NSError * fetchError;
    [self.fetchedResultsController performFetch:&fetchError];
    expect(fetchError).to.beNil();
    expect([self.fetchedResultsController.fetchedObjects count]).will.equal(2);
    
    //Update
    people1.name = @"Tayphoon";
    people1.age = @(30);

    //Delete
    [self.managedObjectContext deleteObject:people2];
    
    //Insert
    CSAnimal * animal = [NSEntityDescription insertNewObjectForEntityForName:@"Animal" inManagedObjectContext:self.managedObjectContext];
    animal.sortOrder = @(2);

    [self.managedObjectContext save:&error];
    expect(error).to.beNil();

    expect([self.fetchedResultsController.fetchedObjects count]).after(1).will.equal(2);
    expect([self.insertedObjects count]).after(1).will.equal(1);
    expect([self.updatedObjects count]).after(1).will.equal(1);
    expect([self.movedObjects count]).after(1).will.equal(0);
    expect([self.deletedObjects count]).after(1).will.equal(1);
}

- (void)testUpdateOrder {
    CSPeople * people1 = [NSEntityDescription insertNewObjectForEntityForName:@"People" inManagedObjectContext:self.managedObjectContext];
    people1.sortOrder = @(0);
    CSAnimal * animal = [NSEntityDescription insertNewObjectForEntityForName:@"Animal" inManagedObjectContext:self.managedObjectContext];
    animal.sortOrder = @(1);
    CSPeople * people2 = [NSEntityDescription insertNewObjectForEntityForName:@"People" inManagedObjectContext:self.managedObjectContext];
    people2.sortOrder = @(2);

    NSError * error;
    [self.managedObjectContext save:&error];
    expect(error).to.beNil();
    
    NSError * fetchError;
    [self.fetchedResultsController performFetch:&fetchError];
    expect(fetchError).to.beNil();
    expect([self.fetchedResultsController.fetchedObjects count]).will.equal(3);
    expect(self.fetchedResultsController.fetchedObjects[0]).will.equal(people1);
    expect(self.fetchedResultsController.fetchedObjects[1]).will.equal(animal);
    expect(self.fetchedResultsController.fetchedObjects[2]).will.equal(people2);
    
    //Reorder
    people2.sortOrder = @(1);
    animal.sortOrder = @(2);
    
    [self.managedObjectContext save:&error];
    expect(error).to.beNil();

    expect([self.fetchedResultsController.fetchedObjects count]).after(1).will.equal(3);
    expect([self.insertedObjects count]).after(1).will.equal(0);
    expect([self.updatedObjects count]).after(1).will.equal(0);
    expect([self.movedObjects count]).after(1).will.equal(2);
    expect([self.deletedObjects count]).after(1).will.equal(0);
    
    expect([self.fetchedResultsController.fetchedObjects count]).will.equal(3);
    expect(self.fetchedResultsController.fetchedObjects[0]).after(1).will.equal(people1);
    expect(self.fetchedResultsController.fetchedObjects[1]).after(1).will.equal(people2);
    expect(self.fetchedResultsController.fetchedObjects[2]).after(1).will.equal(animal);
}

- (void)testInsertFromBackgroundThread {
    NSError * fetchError;
    [self.fetchedResultsController performFetch:&fetchError];
    expect(fetchError).to.beNil();
    expect([self.fetchedResultsController.fetchedObjects count]).will.equal(0);
    
    [self.managedObjectContext performBlockInBackground:^(NSManagedObjectContext * backgroundContext) {
        CSPeople * people1 = [NSEntityDescription insertNewObjectForEntityForName:@"People" inManagedObjectContext:backgroundContext];
        people1.sortOrder = @(0);
        
        NSError * error;
        [backgroundContext saveToPersistentStore:&error];
        expect(error).to.beNil();
    }];
    
    expect([self.fetchedResultsController.fetchedObjects count]).after(2).will.equal(1);
    expect([self.insertedObjects count]).after(2).will.equal(1);
    expect([self.updatedObjects count]).after(2).will.equal(0);
    expect([self.movedObjects count]).after(2).will.equal(0);
    expect([self.deletedObjects count]).after(2).will.equal(0);
}

#pragma mark - Private methods

- (void)controllerWillChangeContent:(TCFetchedResultsController*)controller {
    self.insertedObjects = [NSMutableSet set];
    self.updatedObjects = [NSMutableSet set];
    self.movedObjects = [NSMutableSet set];
    self.deletedObjects = [NSMutableSet set];
}

- (void)controller:(TCFetchedResultsController*)controller
   didChangeObject:(id)anObject
       atIndexPath:(nullable NSIndexPath*)indexPath
     forChangeType:(TCFetchedResultsChangeType)type
      newIndexPath:(nullable NSIndexPath*)newIndexPath {
    switch (type) {
        case TCFetchedResultsChangeInsert:
            [self.insertedObjects addObject:anObject];
            break;
        case TCFetchedResultsChangeDelete:
            [self.deletedObjects addObject:anObject];
            break;
        case TCFetchedResultsChangeUpdate:
            [self.updatedObjects addObject:anObject];
            break;
        case TCFetchedResultsChangeMove:
            [self.movedObjects addObject:anObject];
            break;
    }
}

- (void)controllerDidChangeContent:(TCFetchedResultsController*)controller {
    
}

@end
