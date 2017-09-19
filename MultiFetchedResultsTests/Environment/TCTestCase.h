//
//  TCTestCase.h
//  Tayphoon
//
//  Created by Tayphoon on 31/07/2017.
//  Copyright © 2017 Tayphoon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

/**
 abstract Base class for test cases. Provides initialization of testing infrastructure.
 */
@interface TCTestCase : XCTestCase

@property (nonatomic, readonly) NSManagedObjectContext * managedObjectContext;

- (void)setupInMemoryCoreDataStackWithStoreFileName:(NSString*)storeFileName
                                    concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
                                              error:(NSError**)error;

- (void)cleanUpCoreDataStack;

@end

