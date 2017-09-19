//
//  CSAnimal.h
//  Tayphoon
//
//  Created by Tayphoon on 28.07.17.
//  Copyright © 2017 Tayphoon. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface CSAnimal : NSManagedObject

@property (nonatomic, strong) NSNumber * animalId;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * age;
@property (nonatomic, strong) NSNumber * sortOrder;

@end
