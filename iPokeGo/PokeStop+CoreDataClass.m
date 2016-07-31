//
//  PokeStop+CoreDataClass.m
//  iPokeGo
//
//  Created by Curtis herbert on 7/30/16.
//  Copyright © 2016 Dimitri Dessus. All rights reserved.
//

#import "PokeStop+CoreDataClass.h"
#import "PokeStop+CoreDataProperties.h"

@implementation PokeStop

- (CLLocationCoordinate2D)location
{
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

- (void)syncToValues:(NSDictionary *)values
{
    //this one can only be set on intial creation
    if (!self.identifier) {
        self.identifier = values[@"pokestop_id"];
    }
    
    if (self.lureExpiration != nil && ((id)values[@"lure_expiration"] == [NSNull null] || [values[@"lure_expiration"] integerValue] <= 0)) {
        self.lureExpiration = nil;
        
    } else if ((id)values[@"lure_expiration"] != [NSNull null] && [values[@"lure_expiration"] integerValue] > 0) {
        NSDate *lureExpiration = [NSDate dateWithTimeIntervalSince1970:[values[@"lure_expiration"] integerValue] / 1000];
        
        if (!self.lureExpiration || ![self.lureExpiration isEqualToDate:lureExpiration]) {
            self.lureExpiration = lureExpiration;
        }
    }
    if (!self.latitude) {
        self.latitude = [((NSNumber *)values[@"latitude"]) doubleValue];
    }
    if (!self.longitude) {
        self.longitude = [((NSNumber *)values[@"longitude"]) doubleValue];
    }
}

@end
