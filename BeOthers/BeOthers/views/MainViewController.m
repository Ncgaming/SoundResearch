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
    
    float sampleRate;
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
    sampleRate = 44100.0;
    channels = 2;
    [self initializeAudioSession];
    [self initializeRecorder];
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
	
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &error];
    [audioSession setPreferredHardwareSampleRate:sampleRate error:&error];
    sampleRate = [audioSession currentHardwareSampleRate];

    DLog(@"initialize audio session completed");

}

- (void)initializeRecorder{
    recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];  
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleLossless] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:sampleRate] forKey:AVSampleRateKey];
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
        [avPlayer stop];
    }
    else
    {
        isPlaying = YES;
        [self.playbtn setTitle:@"Stop" forState:UIControlStateNormal];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryAmbient error:&(error)];
        avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordedTmpFile error:&error];
        [avPlayer prepareToPlay];
        [avPlayer play];
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
