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
    AudioStreamBasicDescription    SInt16StreamFormat;		// signed 16 bit int sample format

    AUGraph                         processingGraph;
    BOOL                            playing;
    BOOL                            interruptedDuringPlayback;
    AudioUnit                       mixerUnit;
    
    // fft
    
	//FFTSetup fftSetup;			// fft predefined structure required by vdsp fft functions
	//COMPLEX_SPLIT fftA;			// complex variable for fft
	int fftLog2n;               // base 2 log of fft size
    int fftN;                   // fft size
    int fftNOver2;              // half fft size
	size_t fftBufferCapacity;	// fft buffer size (in samples)
	size_t fftIndex;            // read index pointer in fft buffer 
    
    // working buffers for sample data
    
	void *dataBuffer;               //  input buffer from mic/line
	float *outputBuffer;            //  fft conversion buffer
	float *analysisBuffer;          //  fft analysis buffer
    SInt16 *conversionBufferLeft;   // for data conversion from fixed point to integer
    SInt16 *conversionBufferRight;   // for data conversion from fixed point to integer
    
    // convolution 
    
   	float *filterBuffer;        // impusle response buffer
    int filterLength;           // length of filterBuffer
    float *signalBuffer;        // signal buffer
    int signalLength;           // signal length
    float *resultBuffer;        // result buffer
    int resultLength;           // result length

}
@property(nonatomic, strong) RootViewController *rootViewController;
@property (retain, nonatomic) IBOutlet UIButton *playbtn;
@property (retain, nonatomic) IBOutlet UIButton *recordbtn;
@property (nonatomic) soundStructPtr mySoundStructArrayPtr;
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
