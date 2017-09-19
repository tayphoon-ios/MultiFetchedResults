//
//  CSPeople.h
//  Tayphoon
//
//  Created by Tayphoon on 28.07.17.
//  Copyright © 2017 Tayphoon. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface CSPeople : NSManagedObject

@property (nonatomic, strong) NSNumber * peopleId;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * age;
@property (nonatomic, strong) NSNumber * sortOrder;

@end
