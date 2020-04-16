//
//  LSIQuakeFetcher.m
//  Quakes-Objc
//
//  Created by Paul Solt on 4/16/20.
//  Copyright © 2020 Lambda, Inc. All rights reserved.
//

#import "LSIQuakeFetcher.h"
#import "LSIQuake.h"
#import "LSIQuakeResults.h"
#import "LSIErrors.h"
#import "LSILog.h"

// What other code files do we want to import?

static NSString *baseURLString = @"https://earthquake.usgs.gov/fdsnws/event/1/query";

@implementation LSIQuakeFetcher

// Overriding the NSObject init (we don't need to redeclare in the .h file)
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)fetchQuakesInTimeInterval:(NSDateInterval *)interval
                  completionBlock:(LSIQuakeFetcherCompletionBlock)completionBlock {
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:baseURLString];
    
    // https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2014-01-01&endtime=2014-01-02
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSString *startTimeString = [formatter stringFromDate:interval.startDate];
    NSString *endTimeString = [formatter stringFromDate:interval.endDate];
    
    urlComponents.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"starttime" value:startTimeString],
        [NSURLQueryItem queryItemWithName:@"endtime" value:endTimeString],
        [NSURLQueryItem queryItemWithName:@"format" value:@"geojson"],
    ];
    
    NSURL *url = urlComponents.URL; // FIXME: Can add error handling if value is nil
    
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSLog(@"url: %@", url);

        // Errors
        if (error) {
            completionBlock(nil, error);
            return;
        }
        
        if (!data) {
            NSError *dataError = errorWithMessage(@"No data in URL response for quakes", LSIDataNilError);
            completionBlock(nil, dataError);
            return;
        }
        
        NSError *jsonError = nil; // nil = no error
        
        // & = address of
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        // Future: You may need to check kindOfClass if it's not what we expect!
        
        if (jsonError) {
            completionBlock(nil, jsonError);
            return;
        }
        
        // Decode using our initalizers
        LSIQuakeResults *quakeResults = [[LSIQuakeResults alloc] initWithDictionary:json];
        
        // FIXME: check for non-nil results
        
        completionBlock(quakeResults.quakes, nil);
        
        // call completion handlers
        
    }];

    [task resume];
}

@end
