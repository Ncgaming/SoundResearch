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
    NSMutableDictionary* recordSetting;
}
@end

@implementation MainViewController
@synthesize rootViewController = _rootViewController;
@synthesize playbtn = _playbtn;
@synthesize recordbtn = _recordbtn;
@synthesize stereoStreamFormat;         // stereo format for use in buffer and mixer input for "guitar" sound
@synthesize monoStreamFormat;           // mono format for use in buffer and mixer input for "beats" sound
@synthesize graphSampleRate;            // sample rate to use throughout audio processing chain
@synthesize mixerUnit;                  // the Multichannel Mixer unit
@synthesize playing;                    // Boolean flag to indicate whether audio is playing or not
@synthesize interruptedDuringPlayback;  // Boolean flag to indicate whether audio was playing when an interruption arrived


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.interruptedDuringPlayback = NO;
        
        [self setupAudioSession];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

static OSStatus inputRenderCallback (
                                     
                                     void                        *inRefCon,      // A pointer to a struct containing the complete audio data 
                                     //    to play, as well as state information such as the  
                                     //    first sample to play on this invocation of the callback.
                                     AudioUnitRenderActionFlags  *ioActionFlags, // Unused here. When generating audio, use ioActionFlags to indicate silence 
                                     //    between sounds; for silence, also memset the ioData buffers to 0.
                                     const AudioTimeStamp        *inTimeStamp,   // Unused here.
                                     UInt32                      inBusNumber,    // The mixer unit input bus that is requesting some new
                                     //        frames of audio data to play.
                                     UInt32                      inNumberFrames, // The number of frames of audio to provide to the buffer(s)
                                     //        pointed to by the ioData parameter.
                                     AudioBufferList             *ioData         // On output, the audio data to play. The callback's primary 
                                     //        responsibility is to fill the buffer(s) in the 
                                     //        AudioBufferList.
                                     ) {
    
    soundStructPtr    soundStructPointerArray   = (soundStructPtr) inRefCon;
    UInt32            frameTotalForSound        = soundStructPointerArray[inBusNumber].frameCount;
    BOOL              isStereo                  = soundStructPointerArray[inBusNumber].isStereo;
    
    // Declare variables to point to the audio buffers. Their data type must match the buffer data type.
    AudioUnitSampleType *dataInLeft;
    AudioUnitSampleType *dataInRight;
    
    dataInLeft                 = soundStructPointerArray[inBusNumber].audioDataLeft;
    if (isStereo) dataInRight  = soundStructPointerArray[inBusNumber].audioDataRight;
    
    // Establish pointers to the memory into which the audio from the buffers should go. This reflects
    //    the fact that each Multichannel Mixer unit input bus has two channels, as specified by this app's
    //    graphStreamFormat variable.
    AudioUnitSampleType *outSamplesChannelLeft;
    AudioUnitSampleType *outSamplesChannelRight;
    
    outSamplesChannelLeft                 = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo) outSamplesChannelRight  = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
    
    // Get the sample number, as an index into the sound stored in memory,
    //    to start reading data from.
    UInt32 sampleNumber = soundStructPointerArray[inBusNumber].sampleNumber;
    
    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples 
    //    of audio from the sound stored in memory.
    for (UInt32 frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
        
        outSamplesChannelLeft[frameNumber]                 = dataInLeft[sampleNumber];
        if (isStereo) outSamplesChannelRight[frameNumber]  = dataInRight[sampleNumber];
        
        sampleNumber++;
        
        // After reaching the end of the sound stored in memory--that is, after
        //    (frameTotalForSound / inNumberFrames) invocations of this callback--loop back to the 
        //    start of the sound so playback resumes from there.
        if (sampleNumber >= frameTotalForSound) sampleNumber = 0;
    }
    
    // Update the stored sample number so, the next time this callback is invoked, playback resumes 
    //    at the correct spot.
    soundStructPointerArray[inBusNumber].sampleNumber = sampleNumber;
    
    return noErr;
}


void audioRouteChangeListenerCallback (
                                       void                      *inUserData,
                                       AudioSessionPropertyID    inPropertyID,
                                       UInt32                    inPropertyValueSize,
                                       const void                *inPropertyValue
                                       ) {
    
    // Ensure that this callback was invoked because of an audio route change
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
    
    // This callback, being outside the implementation block, needs a reference to the MixerHostAudio
    //   object, which it receives in the inUserData parameter. You provide this reference when
    //   registering this callback (see the call to AudioSessionAddPropertyListener).
    MainViewController *audioObject = (MainViewController *) inUserData;
    
    // if application sound is not playing, there's nothing to do, so return.
    if (NO == audioObject.isPlaying) {
        
        NSLog (@"Audio route change while application audio is stopped.");
        return;
        
    } else {
        
        // Determine the specific type of audio route change that occurred.
        CFDictionaryRef routeChangeDictionary = inPropertyValue;
        
        CFNumberRef routeChangeReasonRef =
        CFDictionaryGetValue (
                              routeChangeDictionary,
                              CFSTR (kAudioSession_AudioRouteChangeKey_Reason)
                              );
        
        SInt32 routeChangeReason;
        
        CFNumberGetValue (
                          routeChangeReasonRef,
                          kCFNumberSInt32Type,
                          &routeChangeReason
                          );
        
        // "Old device unavailable" indicates that a headset or headphones were unplugged, or that 
        //    the device was removed from a dock connector that supports audio output. In such a case,
        //    pause or stop audio (as advised by the iOS Human Interface Guidelines).
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            
            NSLog (@"Audio output device was removed; stopping audio playback.");
            NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
            [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: audioObject]; 
            
        } else {
            
            NSLog (@"A route change occurred that does not require stopping application audio.");
        }
    }
}


- (void)setupAudioSession {
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback
                     error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error setting audio session category.");
        return;
    }
    
    // Request the desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredHardwareSampleRate: graphSampleRate
                                        error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error setting preferred hardware sample rate.");
        return;
    }
    
    // Activate the audio session
    [mySession setActive: YES
                   error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error activating audio session during initial setup.");
        return;
    }
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [mySession currentHardwareSampleRate];
    
    // Register the audio route change listener callback function with the audio session.
    AudioSessionAddPropertyListener (
                                     kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     self
                                     );
}


- (void)initializeRecorder{
    recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];  
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleLossless] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:graphSampleRate] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
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

#pragma mark -
#pragma mark Utility methods

// You can use this method during development and debugging to look at the
//    fields of an AudioStreamBasicDescription struct.
- (void) printASBD: (AudioStreamBasicDescription) asbd {
    
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10lX",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10lu",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10lu",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10lu",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10lu",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10lu",    asbd.mBitsPerChannel);
}


- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result {
    
    char resultString[5];
    UInt32 swappedResult = CFSwapInt32HostToBig (result);
    bcopy (&swappedResult, resultString, 4);
    resultString[4] = '\0';
    
    NSLog (
           @"*** %@ error: %s %08X %4.4s\n",
           errorString,
           (char*) &resultString
           );
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

    }
    else
    {
        isPlaying = YES;
        [self.playbtn setTitle:@"Stop" forState:UIControlStateNormal];
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
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        int currentFileNum = [AppSettings get].totalFileNum;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSLog(@"issue 1 %@",paths);
        NSString *documentDirectory = [paths objectAtIndex:0];
        
        recordedTmpFile = [NSURL fileURLWithPath:[documentDirectory stringByAppendingPathComponent: [NSString stringWithFormat: @"%i.%@", currentFileNum, @"caf"]]];
        DLog(@"Audio saved in file : %@",recordedTmpFile);
        
        recorder = [[ AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:nil];
        
        [recorder prepareToRecord];
        [recorder record];
        [AppSettings get].totalFileNum = currentFileNum+1;


    }

}
@end
