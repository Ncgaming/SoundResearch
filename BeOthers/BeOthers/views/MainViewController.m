//
//  MainViewController.m
//  BeOthers
//
//  Created by Ncgaming on 30/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "RootViewController.h"

#import "marcoHelper.h"
#import "AppSettings.h"

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>

@interface MainViewController ()
{
    BOOL isRecording;
    BOOL isPlaying;
    NSURL * recordedTmpFile;
	AVAudioRecorder * recorder;
	NSError * error;
    NSMutableDictionary* recordSetting;
    AVAudioPlayer * avPlayer;
    
    AUGraph auGraph;
	AudioUnit	remoteIOUnit;
    
	Float64 hardwareSampleRate;
    int channels;

}
@end

@implementation MainViewController
@synthesize rootViewController = _rootViewController;
@synthesize playbtn = _playbtn;
@synthesize recordbtn = _recordbtn;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    channels = 2;
    [self initializeAudioSession];
    [self initializeRecorder];
    [self setUpAUConnections];
}

- (void)viewDidUnload
{
    [self setPlaybtn:nil];
    [self setRecordbtn:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_playbtn release];
    [_recordbtn release];
    [super dealloc];
}


- (void)initializeAudioSession {
	
    OSStatus setupAudioSessionErr=
	AudioSessionInitialize (
							NULL, // default run loop
							NULL, // default run loop mode
							// MyInterruptionHandler, // interruption callback
							nil, // interruption callback
							self); // client callback data
	NSAssert (setupAudioSessionErr == noErr, @"Couldn't initialize audio session");
	
	UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
	AudioSessionSetProperty 
	(kAudioSessionProperty_AudioCategory,
	 sizeof (sessionCategory),
	 &sessionCategory 
	 ); 	
	NSAssert (setupAudioSessionErr == noErr, @"Couldn't set audio session property");
	
	UInt32 f64PropertySize = sizeof (Float64);
	OSStatus setupErr = 
	AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
							&f64PropertySize,
							&hardwareSampleRate);
	NSAssert (setupErr == noErr, @"Couldn't get current hardware sample rate");
	NSLog (@"current hardware sample rate = %f", hardwareSampleRate);
	
	// is audio input available?
	UInt32 ui32PropertySize = sizeof (UInt32);
	UInt32 inputAvailable;
	setupErr = 
	AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable,
							&ui32PropertySize,
							&inputAvailable);
	NSAssert (setupErr == noErr, @"Couldn't get current audio input available prop");
	// NSLog (@"audio input is %@", (inputAvailable ? @"available" : @"not available"));
	if (! inputAvailable) {
		UIAlertView *noInputAlert =
		[[UIAlertView alloc] initWithTitle:@"No audio input"
								   message:@"No audio input device is currently attached"
								  delegate:nil
						 cancelButtonTitle:@"OK"
						 otherButtonTitles:nil];
		[noInputAlert show];
		[noInputAlert release];
	}
	
	/*
     // listen for changes in mic status
     setupErr = AudioSessionAddPropertyListener (
     kAudioSessionProperty_AudioInputAvailable,
     MyInputAvailableListener,
     self);
     NSAssert (setupAudioSessionErr == noErr, @"Couldn't setup audio input available prop listener");
     */
	
	setupErr = AudioSessionSetActive(true);
    NSAssert (setupAudioSessionErr == noErr, @"Couldn't set audio session active");
	
	


    DLog(@"initialize audio session completed");

}

- (void) setUpAUConnections {
	OSStatus setupErr = noErr;
	
	// describe unit
	AudioComponentDescription audioCompDesc;
	audioCompDesc.componentType = kAudioUnitType_Output;
	audioCompDesc.componentSubType = kAudioUnitSubType_RemoteIO;
	audioCompDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioCompDesc.componentFlags = 0;
	audioCompDesc.componentFlagsMask = 0;
	
	// get rio unit from audio component manager
	AudioComponent rioComponent = AudioComponentFindNext(NULL, &audioCompDesc);
	setupErr = AudioComponentInstanceNew(rioComponent, &remoteIOUnit);
	NSAssert (setupErr == noErr, @"Couldn't get RIO unit instance");
	
	// set up the rio unit for playback
	UInt32 oneFlag = 1;
	AudioUnitElement bus0 = 0;
	setupErr = 
	AudioUnitSetProperty (remoteIOUnit,
						  kAudioOutputUnitProperty_EnableIO,
						  kAudioUnitScope_Output,
						  bus0,
						  &oneFlag,
						  sizeof(oneFlag));
	NSAssert (setupErr == noErr, @"Couldn't enable RIO output");
	
	// setup an asbd in the iphone canonical format
	AudioStreamBasicDescription myASBD;
	memset (&myASBD, 0, sizeof (myASBD));
	myASBD.mSampleRate = 44100.0;
	// myASBD.mSampleRate = hardwareSampleRate;
	myASBD.mFormatID = kAudioFormatLinearPCM;
	myASBD.mFormatFlags = kAudioFormatFlagsCanonical;
	// myASBD.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked; // doesn't matter
	myASBD.mBytesPerPacket = 4;
	myASBD.mFramesPerPacket = 1;
	myASBD.mBytesPerFrame = myASBD.mBytesPerPacket * myASBD.mFramesPerPacket;
	myASBD.mChannelsPerFrame = 2;
	myASBD.mBitsPerChannel = 16;
	
	// set format for output (bus 0) on rio's input scope
	setupErr =
	AudioUnitSetProperty (remoteIOUnit,
						  kAudioUnitProperty_StreamFormat,
						  kAudioUnitScope_Input,
						  bus0,
						  &myASBD,
						  sizeof (myASBD));
	NSAssert (setupErr == noErr, @"Couldn't set ASBD for RIO on input scope / bus 0");
    
	// enable rio input
	AudioUnitElement bus1 = 1;
	setupErr = AudioUnitSetProperty(remoteIOUnit,
									kAudioOutputUnitProperty_EnableIO,
									kAudioUnitScope_Input,
									bus1,
									&oneFlag,
									sizeof(oneFlag));
	NSAssert (setupErr == noErr, @"couldn't enable RIO input");
	
	// set asbd for mic input
	setupErr =
	AudioUnitSetProperty (remoteIOUnit,
						  kAudioUnitProperty_StreamFormat,
						  kAudioUnitScope_Output,
						  1,
						  &myASBD,
						  sizeof (myASBD));
	NSAssert (setupErr == noErr, @"Couldn't set ASBD for RIO on output scope / bus 1");
	
	// direct connect mic to output
	AudioUnitConnection connection;
	connection.sourceAudioUnit = remoteIOUnit;
	connection.sourceOutputNumber = bus1;
	connection.destInputNumber = bus0;
	
	setupErr = 
	AudioUnitSetProperty(remoteIOUnit, 
						 kAudioUnitProperty_MakeConnection,
						 kAudioUnitScope_Input,
						 bus0,
						 &connection,
						 sizeof (connection));
	NSAssert (setupErr == noErr, @"Couldn't set RIO connection");
	
	/*
     // debug - investigate the input asbd
     AudioStreamBasicDescription hwInASBD;
     UInt32 asbdSize = sizeof (hwInASBD);
     setupErr = 
     AudioUnitGetProperty(remoteIOUnit,
     kAudioUnitProperty_StreamFormat,
     kAudioUnitScope_Input,
     bus1,
     &hwInASBD,
     &asbdSize);
     NSLog (@"inspected input ASBD");
	 */
	
	setupErr =	AudioUnitInitialize(remoteIOUnit);
	NSAssert (setupErr == noErr, @"Couldn't initialize RIO unit");
    
}


- (void)initializeRecorder{
    recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];  
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleLossless] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:hardwareSampleRate] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:channels] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    //Encoder Settings (Only necessary if you want to change it.) 
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey]; 
    [recordSetting setValue:[NSNumber numberWithInt:96] forKey:AVEncoderBitRateKey]; 
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVEncoderBitDepthHintKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVSampleRateConverterAudioQualityKey];
    [recorder setDelegate:self];

       
    DLog(@"initialize recorder completed");
}


- (IBAction)tappedPlay:(id)sender {
    if(isRecording)
    {
        //stop recording
    }
    
    if(isPlaying)
    {
        isPlaying = NO;
        [self.playbtn setTitle:@"Play" forState:UIControlStateNormal];
//        [avPlayer stop];
        OSStatus stopErr = noErr;
        stopErr = AudioOutputUnitStop(remoteIOUnit);
        
        NSAssert (stopErr == noErr, @"Couldn't stop RIO unit");
        
        NSLog (@"Stopped RIO unit");

    }
    else
    {
        isPlaying = YES;
        [self.playbtn setTitle:@"Stop" forState:UIControlStateNormal];
//        AVAudioSession *session = [AVAudioSession sharedInstance];
//        [session setCategory:AVAudioSessionCategoryAmbient error:&(error)];
//        avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordedTmpFile error:&error];
//        [avPlayer prepareToPlay];
//        [avPlayer play];
        OSStatus startErr = noErr;
        startErr = AudioOutputUnitStart (remoteIOUnit);
        
        NSAssert (startErr == noErr, @"Couldn't start RIO unit");
        
        NSLog (@"Started RIO unit");

    }
}

- (IBAction)tappedRecord:(id)sender {
    
    if(isPlaying)
    {
        //stop playing
    }
    
    if(isRecording)
    {
        isRecording = NO;
        [self.recordbtn setTitle:@"Record" forState:UIControlStateNormal];
        [recorder stop];
    }
    else
    {
        isRecording = YES;
        [self.recordbtn setTitle:@"Stop Record" forState:UIControlStateNormal];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&(error)];
        
        int currentFileNum = [AppSettings get].totalFileNum;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSLog(@"issue 1 %@",paths);
        NSString *documentDirectory = [paths objectAtIndex:0];
        
        recordedTmpFile = [NSURL fileURLWithPath:[documentDirectory stringByAppendingPathComponent: [NSString stringWithFormat: @"%i.%@", currentFileNum, @"caf"]]];
        DLog(@"Audio saved in file : %@",recordedTmpFile);
        
        recorder = [[ AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error];
        
        [recorder prepareToRecord];
        [recorder record];
        [AppSettings get].totalFileNum = currentFileNum+1;


    }

}
@end
