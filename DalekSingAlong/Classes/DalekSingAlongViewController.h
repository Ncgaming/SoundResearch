//
//  DalekSingAlong.h
//
//  Created by Chris Adamson on 4/13/10.
//  Copyright Subsequently and Furthermore, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

typedef struct {
	AudioUnit rioUnit;
	AudioStreamBasicDescription asbd;
	float sineFrequency;
	float sinePhase;
} EffectState;

typedef struct {
	void* audioData;
	UInt64 audioDataByteCount;
	AudioSampleType *samplePtr;
} MusicPlaybackState;


@interface DalekSingAlongViewController : UIViewController {

	UISlider *micSlider;
	UISlider *musicSlider;
	Float64 hardwareSampleRate;
	AudioUnit	remoteIOUnit;
	AudioUnit mixerUnit;
	EffectState effectState;
	MusicPlaybackState musicPlaybackState;

}

@property (nonatomic, retain) IBOutlet 	UISlider *micSlider;
@property (nonatomic, retain) IBOutlet UISlider *musicSlider;


-(IBAction) handleStartTapped;
-(IBAction) handleMicSliderValueChanged;
-(IBAction) handleMusicSliderValueChanged;


@end

