//
//  AUPassThroughWithDalekEffectViewController.h
//
//  Created by Chris Adamson on 3/21/10.
//  Copyright Subsequently and Furthermore, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Accelerate/Accelerate.h"

@class drawViewController;
typedef struct {
	AudioUnit rioUnit;
	AudioStreamBasicDescription asbd;
	float sineFrequency;
	float sinePhase;
    FFTSetup fftSetup;
} EffectState;

@interface AUPassThroughWithDalekEffectViewController : UIViewController {

	AUGraph auGraph;
	AudioUnit	remoteIOUnit;
	Float64 hardwareSampleRate;
	EffectState effectState;
	COMPLEX_SPLIT fftA;			// complex variable for fft
	int fftLog2n;               // base 2 log of fft size
    int fftN;                   // fft size
    int fftNOver2;              // half fft size
	size_t fftBufferCapacity;	// fft buffer size (in samples)
	size_t fftIndex;            // read index pointer in fft buffer 
}
@property (nonatomic, strong) drawViewController * drawVC1;
@property (nonatomic) AudioUnit	remoteIOUnit;
@property (retain, nonatomic) IBOutlet UIButton *canvas1;
@property FFTSetup fftSetup;			

void smbPitchShift(float pitchShift, long numSampsToProcess, long fftFrameSize, long osamp, float sampleRate, float *indata, float *outdata);

void smb2PitchShift(float pitchShift, long numSampsToProcess, long fftFrameSize,
					long osamp, float sampleRate, float *indata, float *outdata,
					FFTSetup fftSetup, float * frequency);

-(IBAction) handleStartTapped;
- (IBAction)tappedCanvas1:(id)sender;

@end

