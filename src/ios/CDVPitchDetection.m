//
//  CDVPitchDetection.m
//  Basic_Audio_Watermarks
//
//  Created by Andrew Trice on 12/4/12.
//
//

#import "CDVPitchDetection.h"

@implementation CDVPitchDetection

@synthesize isListening;
@synthesize	rioRef;
@synthesize currentFrequency;
@synthesize registeredFrequencies;
static float matchFrequency = 0.0;
static CDVPitchDetection * cid= nil;

//- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView
//{
//    self = [super initWithWebView:theWebView];
//    if (self) {
//        self.registeredFrequencies = [[NSMutableArray alloc] init]; 
//        self.rioRef = [RIOInterface sharedInstance];
//        [rioRef setSampleRate:44100];
//        [rioRef setFrequency:1000];
//        [rioRef initializeAudioSession];
//    }
//    return self;
//}

-(void)pluginInitialize{
    NSLog(@"initialize");
    self.rioRef = [RIOInterface sharedInstance];
    self.registeredFrequencies = [[NSMutableArray alloc] initWithCapacity:10];
    matchFrequency = 0.0;
    [rioRef setSampleRate:44100];
    [rioRef setFrequency:294];
    [rioRef initializeAudioSession];
     NSLog(@"after initialize");
    cid = self;
}


- (void)startListener:(CDVInvokedUrlCommand*)command {
    NSLog(@"Start LIstener");
    isListening = YES;
	[rioRef startListening:self];
    NSLog(@"Start LIstener");
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"listener started"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopListener:(CDVInvokedUrlCommand*)command {
    NSLog(@"Stop LIstener");
    isListening = NO;
	[rioRef stopListening];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"listener stopped"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)registerFrequency:(CDVInvokedUrlCommand*)command {
    
    NSLog(@"registerFrequency called %@", self.registeredFrequencies);
    NSString *frequencyString = [command.arguments objectAtIndex:0];
    float frequency = [frequencyString floatValue];
    BOOL found = FALSE;
    
    NSLog(@"registerFrequency called %f",frequency);
    for (int x = 0; x < [self.registeredFrequencies count]; x++) {
        float _frequency = [[self.registeredFrequencies objectAtIndex:x] floatValue];
        
       NSLog(@"frequency : %f", frequency);
       NSLog(@"_frequency : %f", _frequency);
        
        if ( _frequency == frequency ) {
            found = TRUE;
        }
    }
    NSLog(@"fpund %hhd",found);
    if ( !found ) {
        [self.registeredFrequencies addObject:frequencyString];
        matchFrequency = [frequencyString floatValue];
    }
    NSLog(@"registerfrequency : %@", self.registeredFrequencies);
    NSLog(@"Delegate Class %@", NSStringFromClass([self.commandDelegate class]));
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:self.registeredFrequencies];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)unregisterFrequency:(CDVInvokedUrlCommand*)command {
   // NSLog(@"unregisterFrequency called");
   // NSString* frequency = [command.arguments objectAtIndex:0];
    //TODO
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"frequency unregistered"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}



// This method gets called by the rendering function. Do something with the new frequency
- (void)frequencyChangedWithValue:(float)newFrequency{
    NSLog(@"frequencyChangeWithValue called %f", newFrequency);
//	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
//    
//    
//	[pool drain];
//    pool = nil;
    NSLog( @"frequencyChangedWithValue: %f", matchFrequency);
    @autoreleasepool {
        NSLog( @"frequencyChangedWithValue: %f", matchFrequency );
        
        int x = 0;
        float buffer = 100;
        if(self.registeredFrequencies != NULL){
            NSLog(@"Inside If not null");
            for (x = 0; x < [self.registeredFrequencies count]; x++) {
                float frequency = [[self.registeredFrequencies objectAtIndex:x] floatValue];
                float minFrequency = frequency - buffer;
                float maxFrequency = frequency + buffer;
                
                //  NSLog(@"minFrequency: %f", minFrequency);
                //  NSLog(@"maxFrequency: %f", maxFrequency);
                //   NSLog(@"newFrequency: %f", newFrequency);
                
                if ( newFrequency >= minFrequency && newFrequency <= maxFrequency ) {
                    self.currentFrequency = frequency;
                    [self performSelectorOnMainThread:@selector(updateFrequency) withObject:nil waitUntilDone:NO];
                    break;
                }
            }
        } else {
            NSLog(@"Inside Else");
            float minFrequency = matchFrequency - buffer;
            float maxFrequency = matchFrequency + buffer;
            NSLog(@"minFrequency: %f", minFrequency);
            NSLog(@"maxFrequency: %f", maxFrequency);
            NSLog(@"newFrequency: %f", newFrequency);

            if ( newFrequency >= minFrequency && newFrequency <= maxFrequency ) {
                self.currentFrequency = matchFrequency;
                
                [self performSelectorOnMainThread:@selector(updateFrequency) withObject:nil waitUntilDone:NO];
             
            }
        }


    }
}

- (void)updateFrequency {
   NSLog( @"updateFrequency called %f",self.currentFrequency);
    @autoreleasepool {
        NSDictionary* freqData = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:self.currentFrequency] forKey:@"frequency"];
        //NSString *js = [NSString stringWithFormat:@"window.plugins.pitchDetect.executeCallback('%@')", freqData];
        NSData *jData = [NSJSONSerialization dataWithJSONObject:freqData options:0 error:nil];
        NSString *jsData = [[NSString alloc] initWithData:jData encoding:NSUTF8StringEncoding];
        
        NSString *js = [NSString stringWithFormat:@"window.plugins.pitchDetect.executeCallback('%@')", jsData];
        NSLog( @"js: %@",js );
        NSLog( @"frequencyChangedWithValue: %@",jData );
        [cid.commandDelegate evalJs:js];
        
        matchFrequency = 0.0;
    }
	//NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	//[pool drain];
	//pool = nil;

}

static CDVPitchDetection *sharedInstance = nil;

#pragma mark -
#pragma mark Singleton Methods
+ (CDVPitchDetection *)sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[CDVPitchDetection alloc] init];
    }
    
    return sharedInstance;
}

@end
