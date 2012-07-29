//
//  DalekSingAlong.m
//
//  Created by Chris Adamson on 4/13/10.
//  Copyright Subsequently and Furthermore, Inc. 2010. All rights reserved.
//

#import "DalekSingAlongViewController.h"

@implementation DalekSingAlongViewController

@synthesize micSlider, musicSlider;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

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

#pragma mark callbacks
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
//		NSLog (@"out. currentFrame = %d, inNumberFrames = %d, bufCount = %d",
//			   currentFrame, inNumberFrames, bufCount);
	}
	
	return noErr;
}


OSStatus MusicPlayerCallback (
								   void *							inRefCon,
								   AudioUnitRenderActionFlags *	ioActionFlags,
								   const AudioTimeStamp *			inTimeStamp,
								   UInt32							inBusNumber,
								   UInt32							inNumberFrames,
								   AudioBufferList *				ioData) {
	
	MusicPlaybackState *musicPlaybackState = (MusicPlaybackState*) inRefCon;
		
	// walk the samples
	AudioSampleType sample = 0;
	for (int bufCount=0; bufCount<ioData->mNumberBuffers; bufCount++) {
		AudioBuffer buf = ioData->mBuffers[bufCount];
		// AudioSampleType* bufferedSample = (AudioSampleType*) &buf.mData;
		int currentFrame = 0;
		while ( currentFrame < inNumberFrames ) {
			// copy sample to buffer, across all channels
			for (int currentChannel=0; currentChannel<buf.mNumberChannels; currentChannel++) {
				sample = *musicPlaybackState->samplePtr++;
				memcpy(buf.mData + (currentFrame * 4) + (currentChannel*2),
					   &sample,
					   sizeof(AudioSampleType));
			}	
			currentFrame++;
			// todo: wrap around so we don't crash!
		}
	}
	return noErr;
}

#pragma mark set up units
-(void) setUpAudioUnits {
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
	
	
	// get the mixer unit
	AudioComponentDescription mixerDesc;
	mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
	mixerDesc.componentFlags = 0;
	mixerDesc.componentFlagsMask = 0;
	mixerDesc.componentType = kAudioUnitType_Mixer;
	mixerDesc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	
	// get mixer unit from audio component manager
	AudioComponent mixerComponent = AudioComponentFindNext(NULL, &mixerDesc);
	setupErr = AudioComponentInstanceNew(mixerComponent, &mixerUnit);
	NSAssert (setupErr == noErr, @"Couldn't get mixer unit instance");

	// set mixer bus 0 asbd (robot voice callback)
	setupErr =
	AudioUnitSetProperty (mixerUnit,
						  kAudioUnitProperty_StreamFormat,
						  kAudioUnitScope_Input,
						  bus0,
						  &myASBD,
						  sizeof (myASBD));
	NSAssert (setupErr == noErr, @"Couldn't set ASBD for mixer unit on input scope / bus 0");	

	// song must be an LPCM file, preferably in caf container
	// to convert, use /usr/bin/afconvert, like this:
	//  /usr/bin/afconvert --data LEI16 Girlfriend.m4a song.caf
	
	// read in the entire audio file (NOT recommended)
	// better to use a ring buffer: thread or timer fills, render callback drains
	NSURL *songURL = [NSURL fileURLWithPath:
					  [[NSBundle mainBundle] pathForResource: @"wanqiang"
													  ofType: @"mp3"]];
	AudioFileID songFile;
	setupErr = AudioFileOpenURL((CFURLRef) songURL,
								kAudioFileReadPermission,
								0,
								&songFile);
	NSAssert (setupErr == noErr, @"Couldn't open audio file");
	
	UInt64 audioDataByteCount;
	UInt32 audioDataByteCountSize = sizeof (audioDataByteCount);
	setupErr = AudioFileGetProperty(songFile,
									kAudioFilePropertyAudioDataByteCount,
									&audioDataByteCountSize,
									&audioDataByteCount);
	NSAssert (setupErr == noErr, @"Couldn't get size property");

	musicPlaybackState.audioData = malloc (audioDataByteCount);
	musicPlaybackState.audioDataByteCount = audioDataByteCount;
	musicPlaybackState.samplePtr = musicPlaybackState.audioData;

	NSLog (@"reading %qu bytes from file", audioDataByteCount);
	UInt32 bytesRead = audioDataByteCount;
	setupErr = AudioFileReadBytes(songFile,
								  false,
								  0,
								  &bytesRead,
								  musicPlaybackState.audioData);
	NSAssert (setupErr == noErr, @"Couldn't read audio data");
	NSLog (@"read %d bytes from file", bytesRead);

	AudioStreamBasicDescription fileASBD;
	setupErr = AudioFileGetProperty(songFile,
									kAudioFilePropertyDataFormat,
									&asbdSize,
									&fileASBD);
	NSAssert (setupErr == noErr, @"Couldn't get file asbd");
	
	// set mixer bus 1 asbd (file player callback)
	setupErr =
	AudioUnitSetProperty (mixerUnit,
						  kAudioUnitProperty_StreamFormat,
						  kAudioUnitScope_Input,
						  1,
						  &myASBD,
						  sizeof (fileASBD));
	NSAssert (setupErr == noErr, @"Couldn't set ASBD for mixer unit on input scope / bus 1");	
	
	
	// set up connections and callbacks
	
	// connect mixer bus 0 input to robot voice render callback
	effectState.rioUnit = remoteIOUnit;
	effectState.sineFrequency = 23;
	effectState.sinePhase = 0;
	effectState.asbd = myASBD;
		
	AURenderCallbackStruct effectCallbackStruct;
	effectCallbackStruct.inputProc = DalekVoiceRenderCallback; // callback function
	effectCallbackStruct.inputProcRefCon = &effectState;
	
	setupErr = 
	AudioUnitSetProperty(mixerUnit, 
						 kAudioUnitProperty_SetRenderCallback,
						 kAudioUnitScope_Global,
						 bus0,
						 &effectCallbackStruct,
						 sizeof (effectCallbackStruct));
	NSAssert (setupErr == noErr, @"Couldn't set mixer render callback on bus 0");

	// connect mixer bus 1 input to music player callback
	
	AURenderCallbackStruct musicPlayerCallbackStruct;
	musicPlayerCallbackStruct.inputProc = MusicPlayerCallback; // callback function
	musicPlayerCallbackStruct.inputProcRefCon = &musicPlaybackState;
	
	setupErr = 
	AudioUnitSetProperty(mixerUnit, 
						 kAudioUnitProperty_SetRenderCallback,
						 kAudioUnitScope_Global,
						 1,
						 &musicPlayerCallbackStruct,
						 sizeof (musicPlayerCallbackStruct));
	NSAssert (setupErr == noErr, @"Couldn't set mixer render callback on bus 1");
	
	
	
	// direct connect mixer to output
	AudioUnitConnection connection;
	connection.sourceAudioUnit = mixerUnit;
	connection.sourceOutputNumber = bus0;
	connection.destInputNumber = bus0;
	
	setupErr = 
	AudioUnitSetProperty(remoteIOUnit, 
						 kAudioUnitProperty_MakeConnection,
						 kAudioUnitScope_Input,
						 bus0,
						 &connection,
						 sizeof (connection));
	NSAssert (setupErr == noErr, @"Couldn't set mixer-to-RIO connection");

	setupErr = AudioUnitInitialize(mixerUnit);
	NSAssert (setupErr == noErr, @"Couldn't initialize mixer unit");
	
	setupErr =	AudioUnitInitialize(remoteIOUnit);
	NSAssert (setupErr == noErr, @"Couldn't initialize RIO unit");

	// set inital volume levels
	[self handleMicSliderValueChanged];
	[self handleMusicSliderValueChanged];
	
	NSLog (@"set up mixer and RIO unit");
	
}


#pragma mark event handlers

-(IBAction) handleStartTapped {
	NSLog (@"handleStartTapped");
	OSStatus startErr = noErr;
	startErr = AudioOutputUnitStart (remoteIOUnit);
	NSLog (@"startErr: %d", startErr);
	NSAssert (startErr == noErr, @"Couldn't start RIO unit");
	
	NSLog (@"Started RIO unit");
	
}
-(IBAction) handleMicSliderValueChanged {
	NSLog (@"handleMicSliderValueChanged");
	OSStatus propSetErr = noErr;
	AudioUnitParameterValue sliderVal = [micSlider value];
	propSetErr = AudioUnitSetParameter(mixerUnit,
									   kMultiChannelMixerParam_Volume,
									   kAudioUnitScope_Input,
									   0,
									   sliderVal,
									   0);
	NSAssert (propSetErr == noErr, @"Couldn't set mixer volume on bus 0");
}

-(IBAction) handleMusicSliderValueChanged{
	NSLog (@"handleMusicSliderValueChanged");
	OSStatus propSetErr = noErr;
	AudioUnitParameterValue sliderVal = [musicSlider value];
	propSetErr = AudioUnitSetParameter(mixerUnit,
									   kMultiChannelMixerParam_Volume,
									   kAudioUnitScope_Input,
									   1,
									   sliderVal,
									   0);
	NSAssert (propSetErr == noErr, @"Couldn't set mixer volume on bus 1");
	
}


#pragma mark vc lifecycle


/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


/*
 */
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self setUpAudioSession];
	[self setUpAudioUnits];
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
