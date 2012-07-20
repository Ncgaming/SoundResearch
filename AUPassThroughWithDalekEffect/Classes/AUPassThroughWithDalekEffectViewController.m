//
//  AUPassThroughWithDalekEffectViewController.m
//
//  Created by Chris Adamson on 3/21/10.
//  Copyright Subsequently and Furthermore, Inc. 2010. All rights reserved.
//

#import "AUPassThroughWithDalekEffectViewController.h"
#import "Accelerate/Accelerate.h"
#import "drawViewController.h"

@implementation AUPassThroughWithDalekEffectViewController

@synthesize remoteIOUnit;
@synthesize canvas1;
@synthesize fftSetup;
@synthesize drawVC1 = _drawVC1;

#pragma mark init/dealloc
/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/
- (void)dealloc {
    [canvas1 release];
    [super dealloc];
}

#pragma mark setup au
- (void) setUpAudioSession {
	NSLog(@"setUpAudioSession");
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
	
	
}


OSStatus FFTPitchShift (
								   void *							inRefCon,
								   AudioUnitRenderActionFlags *	ioActionFlags,
								   const AudioTimeStamp *			inTimeStamp,
								   UInt32							inBusNumber,
								   UInt32							inNumberFrames,
								   AudioBufferList *				ioData) {
	
	EffectState *effectState = (EffectState*) inRefCon;
	AudioUnit rioUnit = effectState->rioUnit;
	AudioStreamBasicDescription asbd = effectState->asbd;
	OSStatus renderErr = noErr;
	UInt32 bus1 = 1;
	
	// just copy samples
	renderErr = AudioUnitRender(rioUnit,
								ioActionFlags,
								inTimeStamp,
								bus1,
								inNumberFrames,
								ioData);
	uint32_t stride = 1;                    // interleaving factor for vdsp functions
	int bufferCapacity = inNumberFrames;    // maximum size of fft buffers
    void * sampleBuffer = ioData->mBuffers[0].mData;
    
    float pitchShift = 1.0;                 // pitch shift factor 1=normal, range is .5->2.0
    long osamp = 4;                         // oversampling factor
    long fftSize = inNumberFrames;                    // fft size 
    
	
	float frequency;                        // analysis frequency result
    
    float *analysisBuffer;
    float *outputBuffer;
    outputBuffer = (float*)malloc(inNumberFrames *sizeof(float));
	analysisBuffer = (float*)malloc(inNumberFrames *sizeof(float));
    //	ConvertInt16ToFloat
    
    vDSP_vflt16((SInt16 *) sampleBuffer, stride, (float *) analysisBuffer, stride, bufferCapacity );
    
    // run the pitch shift
    
    // scale the fx control 0->1 to range of pitchShift .5->2.0
    
    pitchShift = (0.3 * 1.5) + .5;
    
    // osamp should be at least 4, but at this time my ipod touch gets very unhappy with 
    // anything greater than 2
    
    osamp = 4;
    fftSize = inNumberFrames;		// this seems to work in real time since we are actually doing the fft on smaller windows
    
    smb2PitchShift( pitchShift , (long) inNumberFrames,
                   fftSize,  osamp, (float)asbd.mSampleRate,
                   (float *) analysisBuffer , (float *) outputBuffer,
                   effectState->fftSetup, &frequency);
    
    
    
    
    
    
    // very very cool effect but lets skip it temporarily    
    //    THIS.sinFreq = THIS.frequency;   // set synth frequency to the pitch detected by microphone
    
    
    
    // now convert from float to Sint16
    
    vDSP_vfixr16((float *) outputBuffer, stride, (SInt16 *) sampleBuffer, stride, bufferCapacity );

    
    
    
    
    

	return noErr;
}






OSStatus DalekVoiceRenderCallback (
								   void *							inRefCon,
								   AudioUnitRenderActionFlags *	ioActionFlags,
								   const AudioTimeStamp *			inTimeStamp,
								   UInt32							inBusNumber,
								   UInt32							inNumberFrames,
								   AudioBufferList *				ioData) {
	
	EffectState *effectState = (EffectState*) inRefCon;
    
	AudioUnit rioUnit = effectState->rioUnit;
	AudioStreamBasicDescription asbd = effectState->asbd;
	float sineFrequency = effectState->sineFrequency;
	// float sinePhase = effectState->sinePhase;
	OSStatus renderErr = noErr;
	UInt32 bus1 = 1;
	
	// just copy samples
	renderErr = AudioUnitRender(rioUnit,
								ioActionFlags,
								inTimeStamp,
								bus1,
								inNumberFrames,
								ioData);
	
	// walk the samples
	AudioSampleType sample = 0;
	for (int bufCount=0; bufCount<ioData->mNumberBuffers; bufCount++) {
		AudioBuffer buf = ioData->mBuffers[bufCount];
		// AudioSampleType* bufferedSample = (AudioSampleType*) &buf.mData;
		int currentFrame = 0;
		while ( currentFrame < inNumberFrames ) {
			// copy sample to buffer, across all channels
			for (int currentChannel=0; currentChannel<buf.mNumberChannels; currentChannel++) {
				memcpy(&sample,
					   buf.mData + (currentFrame * 4) + (currentChannel*2),
					   sizeof(AudioSampleType));
				
				float theta = effectState->sinePhase * M_PI * 2;
				
				sample = (sin(theta) * sample);
				
				memcpy(buf.mData + (currentFrame * 4) + (currentChannel*2),
					   &sample,
					   sizeof(AudioSampleType));
				
				effectState->sinePhase += 1.0 / (asbd.mSampleRate / sineFrequency);
				if (effectState->sinePhase > 1.0) {
					effectState->sinePhase -= 1.0;
				}
			}	
			currentFrame++;
		}
	}
	return noErr;
}




#pragma mark direct RIO use

- (void) setUpAUConnectionsWithRenderCallback {
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
	
	// enable rio input
	AudioUnitElement bus1 = 1;
	setupErr = AudioUnitSetProperty(remoteIOUnit,
									kAudioOutputUnitProperty_EnableIO,
									kAudioUnitScope_Input,
									bus1,
									&oneFlag,
									sizeof(oneFlag));
	NSAssert (setupErr == noErr, @"couldn't enable RIO input");
	
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
	
	// setup an asbd in the iphone canonical format
	AudioStreamBasicDescription myASBD;
	memset (&myASBD, 0, sizeof (myASBD));
	// myASBD.mSampleRate = 44100;
	myASBD.mSampleRate = hardwareSampleRate;
	myASBD.mFormatID = kAudioFormatLinearPCM;
	myASBD.mFormatFlags = kAudioFormatFlagsCanonical;
	myASBD.mBytesPerPacket = 4;
	myASBD.mFramesPerPacket = 1;
	myASBD.mBytesPerFrame = 4;
	myASBD.mChannelsPerFrame = 2;
	myASBD.mBitsPerChannel = 16;
	
	/*
	 // set format for output (bus 0) on rio's input scope
	 */
	setupErr =
	AudioUnitSetProperty (remoteIOUnit,
						  kAudioUnitProperty_StreamFormat,
						  kAudioUnitScope_Input,
						  bus0,
						  &myASBD,
						  sizeof (myASBD));
	NSAssert (setupErr == noErr, @"Couldn't set ASBD for RIO on input scope / bus 0");
	
	
	// set asbd for mic input
	setupErr =
	AudioUnitSetProperty (remoteIOUnit,
						  kAudioUnitProperty_StreamFormat,
						  kAudioUnitScope_Output,
						  bus1,
						  &myASBD,
						  sizeof (myASBD));
	NSAssert (setupErr == noErr, @"Couldn't set ASBD for RIO on output scope / bus 1");
	
	// more info on ring modulator and dalek voices at:
	// // http://homepage.powerup.com.au/~spratleo/Tech/Dalek_Voice_Primer.html
	effectState.rioUnit = remoteIOUnit;
	effectState.asbd = myASBD;
	effectState.sineFrequency = 23;
	effectState.sinePhase = 0;
	
	// set callback method
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = FFTPitchShift; // callback function
	callbackStruct.inputProcRefCon = &effectState;
	
	setupErr = 
	AudioUnitSetProperty(remoteIOUnit, 
						 kAudioUnitProperty_SetRenderCallback,
						 kAudioUnitScope_Global,
						 bus0,
						 &callbackStruct,
						 sizeof (callbackStruct));
	NSAssert (setupErr == noErr, @"Couldn't set RIO render callback on bus 0");
	
	
	setupErr =	AudioUnitInitialize(remoteIOUnit);
	NSAssert (setupErr == noErr, @"Couldn't initialize RIO unit");
	
}






#pragma mark vc lifecycle
/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
*/
- (void)viewDidLoad {
    [super viewDidLoad];
	[self setUpAudioSession];
	[self setUpAUConnectionsWithRenderCallback];
    [self FFTSetup];
    
    effectState.fftSetup = self.fftSetup;
    
    self.drawVC1 = [[drawViewController alloc]init];
    [self.view addSubview:self.drawVC1.view];
    self.drawVC1.view.hidden = YES;
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    
    
    
    
}
     

- (void) FFTSetup {
         
         // I'm going to just convert everything to 1024
         
         
         // on the simulator the callback gets 512 frames even if you set the buffer to 1024, so this is a temp workaround in our efforts
         // to make the fft buffer = the callback buffer, 
         
         
         // for smb it doesn't matter if frame size is bigger than callback buffer
         
         UInt32 maxFrames = 1024;    // fft size
         
         
         // setup input and output buffers to equal max frame size
         
//         dataBuffer = (void*)malloc(maxFrames * sizeof(SInt16));
//         outputBuffer = (float*)malloc(maxFrames *sizeof(float));
//         analysisBuffer = (float*)malloc(maxFrames *sizeof(float));
         
         // set the init stuff for fft based on number of frames
         
         fftLog2n = log2f(maxFrames);		// log base2 of max number of frames, eg., 10 for 1024
         fftN = 1 << fftLog2n;					// actual max number of frames, eg., 1024 - what a silly way to compute it
         
         
         fftNOver2 = maxFrames/2;                // half fft size
         fftBufferCapacity = maxFrames;          // yet another way of expressing fft size
         fftIndex = 0;                           // index for reading frame data in callback
         
         // split complex number buffer
         fftA.realp = (float *)malloc(fftNOver2 * sizeof(float));		// 
         fftA.imagp = (float *)malloc(fftNOver2 * sizeof(float));		// 
         
         
         // zero return indicates an error setting up internal buffers
         
         fftSetup = vDSP_create_fftsetup(fftLog2n, FFT_RADIX2);
         if( fftSetup == (FFTSetup) 0) {
             NSLog(@"Error - unable to allocate FFT setup buffers" );
         }
         
     }


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setCanvas1:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark event handlers
-(IBAction) handleStartTapped {
	
	OSStatus startErr = noErr;
	startErr = AudioOutputUnitStart (remoteIOUnit);
	
	NSAssert (startErr == noErr, @"Couldn't start RIO unit");
	
	NSLog (@"Started RIO unit");
}

- (IBAction)tappedCanvas1:(id)sender {
    self.drawVC1.view.hidden = NO;
}

@end
