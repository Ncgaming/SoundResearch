//
//  MainViewController.h
//  BeOthers
//
//  Created by Ncgaming on 30/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>

@class RootViewController;
#define NUM_FILES 1

typedef struct {
    
    BOOL                 isStereo;           // set to true if there is data in the audioDataRight member
    UInt32               frameCount;         // the total number of frames in the audio data
    UInt32               sampleNumber;       // the next audio sample to play
    AudioUnitSampleType  *audioDataLeft;     // the complete left (or mono) channel of audio data read from an audio file
    AudioUnitSampleType  *audioDataRight;    // the complete right channel of audio data read from an audio file
    
} soundStruct, *soundStructPtr;

@interface MainViewController : UIViewController<AVAudioRecorderDelegate, AVAudioSessionDelegate>
{
    Float64                         graphSampleRate;
    CFURLRef                        sourceURLArray[NUM_FILES];
    soundStruct                     soundStructArray[NUM_FILES];
    
    // Before using an AudioStreamBasicDescription struct you must initialize it to 0. However, because these ASBDs
    // are declared in external storage, they are automatically initialized to 0.
    AudioStreamBasicDescription     stereoStreamFormat;
    AudioStreamBasicDescription     monoStreamFormat;
    AUGraph                         processingGraph;
    BOOL                            playing;
    BOOL                            interruptedDuringPlayback;
    AudioUnit                       mixerUnit;

}
@property(nonatomic, strong) RootViewController *rootViewController;
@property (retain, nonatomic) IBOutlet UIButton *playbtn;
@property (retain, nonatomic) IBOutlet UIButton *recordbtn;
- (IBAction)tappedPlay:(id)sender;
- (IBAction)tappedRecord:(id)sender;

@property (readwrite)           AudioStreamBasicDescription stereoStreamFormat;
@property (readwrite)           AudioStreamBasicDescription monoStreamFormat;
@property (readwrite)           Float64                     graphSampleRate;
@property (getter = isPlaying)  BOOL                        playing;
@property                       BOOL                        interruptedDuringPlayback;
@property                       AudioUnit                   mixerUnit;

- (void) obtainSoundFileURLs;
- (void) setupAudioSession;
- (void) setupStereoStreamFormat;
- (void) setupMonoStreamFormat;

- (void) readAudioFilesIntoMemory;

- (void) configureAndInitializeAudioProcessingGraph;
- (void) startAUGraph;
- (void) stopAUGraph;

- (void) enableMixerInput: (UInt32) inputBus isOn: (AudioUnitParameterValue) isONValue;
- (void) setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) inputGain;
- (void) setMixerOutputGain: (AudioUnitParameterValue) outputGain;

- (void) printASBD: (AudioStreamBasicDescription) asbd;
- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result;

@end
