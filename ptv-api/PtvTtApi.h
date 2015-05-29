//
//  Created by Dennis Weaver on 25/03/2014.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface PtvTtApi : NSObject

typedef void (^completionBlock) (id data);

-(id) initWithPath:(NSString*)path devId:(NSString*)devId key:(NSString*)key;
-(id) initWithDevId:(NSString*)devId key:(NSString*)key;

-(BOOL) healthCheck;

-(id) transportPOIsByMap:(NSString*)poiTypes
                             fromLat:(NSNumber*)lat1
                            fromLong:(NSNumber*)long1
                               toLat:(NSNumber*)lat2
                              toLong:(NSNumber*)long2
                           withDepth:(NSNumber*)gridDepth
                           withLimit:(NSNumber*)limit
                      withCompletion:(completionBlock)completion;

-(id) search:(NSString*)searchText withCompletion:(completionBlock)completion;

-(id) nearby:(CLLocation*)location withCompletion:(completionBlock)completion;

-(id) departuresForMode:(NSString*)mode stop:(NSNumber*)stop limit:(NSNumber*)limit withCompletion:(completionBlock)completion;

-(id) departuresForMode:(NSString*)mode stop:(NSNumber*)stop line:(NSNumber*)line direction:(NSNumber*)direction limit:(NSNumber*)limit date:(NSDate*)date withCompletion:(completionBlock)completion;

-(id) linesForMode:(NSNumber*)mode withCompletion:(completionBlock)completion;

-(id) stopsForLine:(NSNumber*)line mode:(NSString*)mode withCompletion:(completionBlock)completion;

-(NSDictionary*) stoppingPatternForDeparture:(NSDictionary*)departure withCompletion:(completionBlock)completion;


@end
