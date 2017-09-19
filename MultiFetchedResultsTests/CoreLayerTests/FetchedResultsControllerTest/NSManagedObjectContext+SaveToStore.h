//
//  NSManagedObjectContext+SaveToStore.h
//  Tayphoon
//
//  Created by Tayphoon on 22.08.17.
//  Copyright © 2017 Tayphoon. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (SaveToStore)

- (BOOL)saveToPersistentStore:(NSError**)error;

@end
