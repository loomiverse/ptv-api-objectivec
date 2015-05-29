//
//  Created by Dennis Weaver on 25/03/2014.
//  Copyright (c) 2014. All rights reserved.
//

#import "PtvTtApi.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <SystemConfiguration/SystemConfiguration.h>


@implementation PtvTtApi

NSString* mDevId;
NSString* mKey;
NSString* mBaseURL;

NSArray * mLines;
NSDictionary *mTtIds;


-(id) initWithPath:(NSString*)path devId:(NSString*)devId key:(NSString*)key
{
    self = [super init];
    
    if( self)
    {
        mBaseURL = path;
        mDevId = devId;
        mKey = key;
        mLines = nil;
        mTtIds = @{@"train":@(0),
                   @"tram":@(1),
                   @"bus":@(2),
                   @"vline":@(3),
                   @"nightrider":@(4)};
    }
    
    return self;
}

-(id) initWithDevId:(NSString*)devId key:(NSString*)key
{
  return [self initWithPath:@"http://timetableapi.ptv.vic.gov.au" devId:devId key:key];
}

-(BOOL) healthCheck
{
    NSDictionary *response = [self doApiCall:[NSString stringWithFormat:@"/v2/healthcheck?timestamp=%@", [PtvTtApi UTCrfc822Date:[NSDate date] ]] useCache:NO withCompletion:nil];
    
    
    return [response[@"clientClockOK"] integerValue] == 1
    &&  [response[@"databaseOK"] integerValue] == 1
    &&  [response[@"memcacheOK"] integerValue] == 1
    &&  [response[@"securityTokenOK"] integerValue] == 1;
    
}



-(NSDictionary *) transportPOIsByMap:(NSString*)poiTypes fromLat:(NSNumber*)lat1 fromLong:(NSNumber*)long1
                             toLat:(NSNumber*)lat2 toLong:(NSNumber*)long2
                         withDepth:(NSNumber*)gridDepth withLimit:(NSNumber*)limit
                      withCompletion:(completionBlock)completion
{
    
    NSString* request;
    
    request = [NSString stringWithFormat:@"/v2/poi/%@/lat1/%@/long1/%@/lat2/%@/long2/%@/griddepth/%@/limit/%@", poiTypes, lat1, long1, lat2, long2, gridDepth, limit ];
    
    NSDictionary * response = [self doApiCall:request withCompletion:completion];
    
    return response;
}

-(NSArray*) search:(NSString*)searchText withCompletion:(completionBlock)completion
{    
    searchText = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    return  [self doApiCall:[NSString stringWithFormat:@"/v2/search/%@", searchText] withCompletion:completion];
}

-(NSArray*) nearby:(CLLocation*)location withCompletion:(completionBlock)completion
{
    return [self doApiCall:[NSString stringWithFormat:@"/v2/nearme/latitude/%f/longitude/%f?limit=5", location.coordinate.latitude, location.coordinate.longitude] withCompletion:completion];
}

-(NSDictionary*) departuresForMode:(NSString*)mode stop:(NSNumber*)stop limit:(NSNumber*)limit withCompletion:(completionBlock)completion
{
    NSString* request;
    
    request = [NSString stringWithFormat:@"/v2/mode/%@/stop/%@/departures/by-destination/limit/%@", [PtvTtApi transportTypeToMode:mode], stop, limit ];
    
    return [self doApiCall:request useCache:[limit isEqualToNumber:@(0)] withCompletion:completion];
}



-(NSDictionary*) departuresForMode:(NSString*)mode stop:(NSNumber*)stop date:(NSDate*)date withCompletion:(completionBlock)completion
{
    NSString* request;
    
    request = [NSString stringWithFormat:@"/v2/mode/%@/stop/%@/departures/by-destination/limit/0?for_utc=%@", [PtvTtApi transportTypeToMode:mode], stop, [PtvTtApi UTCrfc822Date:date] ];
    
    return [self doApiCall:request withCompletion:completion];
}



-(NSDictionary*) departuresForMode:(NSString*)mode stop:(NSNumber*)stop line:(NSNumber*)line direction:(NSNumber*)direction limit:(NSNumber*)limit date:(NSDate*)date withCompletion:(completionBlock)completion
{
    NSString* request;
    
    if( date != nil)
        request = [NSString stringWithFormat:@"/v2/mode/%@/line/%@/stop/%@/directionid/%@/departures/all/limit/%@?for_utc=%@", [PtvTtApi transportTypeToMode:mode], line, stop, direction, limit, [PtvTtApi UTCrfc822Date:date] ];
    else
        request = [NSString stringWithFormat:@"/v2/mode/%@/line/%@/stop/%@/directionid/%@/departures/all/limit/%@", [PtvTtApi transportTypeToMode:mode], line, stop, direction, limit ];
    
    return [self doApiCall:request withCompletion:completion];
}


-(NSArray*) linesForMode:(NSNumber*)mode withCompletion:(completionBlock)completion
{
    
    
    NSString* request;
    
    request = [NSString stringWithFormat:@"/v2/lines/mode/%@", mode ];
    
    return [self doApiCall:request withCompletion:completion];
}

-(NSArray*) stopsForLine:(NSNumber*)line mode:(NSString*)mode withCompletion:(completionBlock)completion
{
    NSString* request;
    
    request = [NSString stringWithFormat:@"/v2/mode/%@/line/%@/stops-for-line", [PtvTtApi transportTypeToMode:mode], line ];
    
    return [self doApiCall:request withCompletion:completion];
}

-(NSDictionary*) stoppingPatternForDeparture:(NSDictionary*)departure withCompletion:(completionBlock)completion
{
    NSDictionary *run = departure[@"run"];

    return [self stoppingPatternForRun:run[@"transport_type"]
                                   run:run[@"run_id"]
                                  stop:departure[@"platform"][@"stop"][@"stop_id"]
                                  time:[PtvTtApi departureToLocalDate:departure]
                        withCompletion:completion];
}

-(NSDictionary*) stoppingPatternForRun:(NSString*)mode run:(NSNumber*)run stop:(NSNumber*)stop time:(NSDate*)time withCompletion:(completionBlock)completion
{
    NSString* request;
    
    request = [NSString stringWithFormat:@"/v2/mode/%@/run/%@/stop/%@/stopping-pattern?for_utc=%@", [PtvTtApi transportTypeToMode:mode], run, stop,  [PtvTtApi UTCrfc822Date:time ]];
    
    return [self doApiCall:request withCompletion:completion];

}


+(NSString*) urlEncode:(NSString*)unencodedString
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)unencodedString,
                                                               NULL,
                                                               (CFStringRef)@"!*'();:@&=+$,/?%#[] ",
                                                               kCFStringEncodingUTF8 ));
}

-(id) doApiCall:(NSString*)apiCall withCompletion:(completionBlock)completion
{
    return [self doApiCall:apiCall useCache:YES withCompletion:completion];
}

-(id) doApiCall:(NSString*)apiCall useCache:(BOOL)useCache withCompletion:(completionBlock)completion
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", mBaseURL, [PtvTtApi signApiCall:apiCall]]];
    
    id response = [self httpWrapper:url withCompletion:completion];
    
    return response;
}


-(id) httpWrapper:(NSURL*)url withCompletion:(completionBlock)completion
{
    __block id response = nil;

    void (^doStuff)() = ^void()
    {
        int retry = 3;
        NSError * error;

        
        while( retry > 0) {
            NSData * data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url
                                                                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                                 timeoutInterval:600] returningResponse:nil error:&error ];
            
            if( data != nil )
            {
                response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if( response != nil)
                    retry = 0;
            }
            
            if(data == nil || response == nil)
            {
                NSLog(@"Bad response %@", url);
                NSLog(@"%@", error);
                --retry;
            }
        }
    };
    
    if( completion != nil)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            doStuff();
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion( response );
            });
        });
    }
    else
    {
        doStuff();
    }
    
    return response;
}

+(NSString*) signApiCall:(NSString*)apiCall
{
    NSString* signedApiCall;
    NSString* signature;

    if([apiCall rangeOfString:@"?"].location != NSNotFound)
        signedApiCall = [NSString stringWithFormat:@"%@&devid=%@", apiCall, mDevId];
    else
        signedApiCall = [NSString stringWithFormat:@"%@?devid=%@", apiCall, mDevId];

    signature = [PtvTtApi hmac:signedApiCall withKey:mKey];

    return [NSString stringWithFormat:@"%@&signature=%@", signedApiCall, signature];
}


//ripped shamelessly from http://stackoverflow.com/questions/756492/objective-c-sample-code-for-hmac-sha1
+(NSString *)hmac:(NSString *)plainText withKey:(NSString *)key
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [plainText cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMACData = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    const unsigned char *buffer = (const unsigned char *)[HMACData bytes];
    NSString *HMAC = [NSMutableString stringWithCapacity:HMACData.length * 2];
    
    for (int i = 0; i < HMACData.length; ++i)
        HMAC = [HMAC stringByAppendingFormat:@"%02lX", (unsigned long)buffer[i]];
    
    return HMAC;
}

+(NSString *)UTCrfc822Date:(NSDate*)datetime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    return [dateFormatter stringFromDate:datetime];
}

+(NSString *) modeToTransportType:(NSNumber*)mode
{
    return  [[mTtIds keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        *stop = [obj isEqualToNumber:mode];
        return  *stop;
    }] anyObject];
}

+(NSNumber*) transportTypeToMode:(NSString*)transportType
{
    return mTtIds[transportType];
}


-(BOOL) haveComms:(NSString*)hostName
{
    BOOL retval = NO;
    SCNetworkReachabilityFlags flags;
    
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    
    
    if( SCNetworkReachabilityGetFlags( ref, &flags) )
    {
        if ((flags & kSCNetworkReachabilityFlagsReachable) )
        {
            retval = YES;
        }
    }
    
    return retval;
}

+(NSDate*) apiDateStringToLocalDate:(NSString*)dateString
{
    // there must be a better way to do this
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSDate * utcDate = [dateFormatter dateFromString:dateString];
    
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: utcDate];
    NSDate * localDate = [NSDate dateWithTimeInterval: seconds sinceDate: utcDate];
    
    return localDate;
}

+(NSDate*) departureToLocalDate:(NSDictionary*)departure
{
    NSString * dateString;
    
    dateString = departure[@"time_realtime_utc"];
    
    if( [dateString isKindOfClass:[NSNull class]] )
        dateString = departure[@"time_timetable_utc"];
    
    return [PtvTtApi apiDateStringToLocalDate:dateString];
    
}



@end

