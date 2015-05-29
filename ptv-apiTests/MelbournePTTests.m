//
//  Created by Dennis Weaver on 25/03/2014.
//  Copyright (c) 2014. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PtvTtApi.h"

@interface MelbournePTTests : XCTestCase

@end

@implementation MelbournePTTests

PtvTtApi *ptvtt;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    ptvtt =[[PtvTtApi alloc] initWithDevId:@"1000001" key:@"12345678-abcd-1234-fgab-1234567890ab"];

}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
}

- (void)testHealthcheck
{
    XCTAssertTrue([ptvtt healthCheck], "Healthcheck failed");
}

-(void) testPois
{
    
    NSDictionary * response = [ptvtt transportPOIsByMap:@"0,1,2,3,4,100"
                                                fromLat:@(90)
                                               fromLong:@(-180)
                                                  toLat:@(-90)
                                                 toLong:@(180)
                                              withDepth:@(0)
                                              withLimit:@(50)
                               withCompletion:nil];
    
    XCTAssertNil(response[@"Error"] , "Search all failed");
    XCTAssertTrue([response[@"locations"] count]  == 50, @"pois for world failed");
}

- (void)testSearchAll
{
    
    NSDictionary * response = [ptvtt search:@"Line" withCompletion:nil];
    XCTAssertTrue([response isKindOfClass:[NSArray class]]);
    XCTAssertTrue([response count] > 0, "Search all failed");
}

- (void)testDeparturesForStop
{
    NSDictionary * response = [ptvtt departuresForMode:@"vline" stop:@(1513) limit:@(1) withCompletion:nil];
    XCTAssertNil(response[@"Error"] , "Search all failed");
    XCTAssertTrue([response count] > 0, "Search all failed");
}


-(void) testLinesForModeTrain
{
    NSArray * response = [ptvtt linesForMode:@(0) withCompletion:nil];
    NSLog(@"Found %ld train lines", [response count]);
    XCTAssertTrue([response isKindOfClass:[NSArray class]]);
    XCTAssertTrue([response count] > 0, "Get train lines failed");
}

-(void) testLinesForModeTram
{
    NSArray * response = [ptvtt linesForMode:@(1) withCompletion:nil];
    NSLog(@"Found %ld tram routes", [response count]);
    XCTAssertTrue([response isKindOfClass:[NSArray class]]);
    XCTAssertTrue([response count] > 0, "Get tram routes failed");
}

-(void) testLinesForModeBus
{
    NSArray * response = [ptvtt linesForMode:@(2) withCompletion:nil];
    NSLog(@"Found %ld bus routes", [response count]);
    XCTAssertTrue([response isKindOfClass:[NSArray class]]);
    XCTAssertTrue([response count] > 0, "Get bus routes failed");
}

-(void) testLinesForModeVLine
{
    NSArray * response = [ptvtt linesForMode:@(3) withCompletion:nil];
    NSLog(@"Found %ld VLine lines", [response count]);
    XCTAssertTrue([response isKindOfClass:[NSArray class]]);
    XCTAssertTrue([response count] > 0, "Get vline routes/lines failed");
}

-(void) testLinesForModeNightrider
{
    NSArray * response = [ptvtt linesForMode:@(4) withCompletion:nil];
    NSLog(@"Found %ld nightrider routes", [response count]);
    XCTAssertTrue([response isKindOfClass:[NSArray class]]);
    XCTAssertTrue([response count] > 0, "Get nightrider routes failed");
}

-(void) testStopsForLine
{
    NSArray * response = [ptvtt stopsForLine:@(1) mode:@"train" withCompletion:nil];
    NSLog(@"Found %ld stops", [response count]);
    XCTAssertTrue([response isKindOfClass:[NSArray class]]);
    XCTAssertTrue([response count] > 0, "Stops For Line failed");
}

@end
