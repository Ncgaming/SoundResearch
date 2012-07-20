//
//  record_audio_testViewController.m
//  record_audio_test
//
//  Created by jinhu zhang on 11-1-5.
//  Copyright 2011 no. All rights reserved.
//

#import "record_audio_testViewController.h"

@implementation record_audio_testViewController
@synthesize actSpinner, btnStart, btnPlay;

@synthesize m_pLongMusicPlayer;
- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Start the toggle in true mode.
	toggle = YES;
	btnPlay.hidden = YES;
	
	//Instanciate an instance of the AVAudioSession object.
	AVAudioSession * audioSession = [AVAudioSession sharedInstance];
	//Setup the audioSession for playback and record. 
	//We could just use record and then switch it to playback leter, but
	//since we are going to do both lets set it up once.
	[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &error];
	//Activate the session
	[audioSession setActive:YES error: &error];
	NSString *musicFilePath = [[NSBundle mainBundle] pathForResource:@"44th Street Long" ofType:@"caf"];       //创建音乐文件路径
	NSURL *musicURL = [[NSURL alloc] initFileURLWithPath:musicFilePath];  
	
	m_pLongMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL error:nil];
	
}
- (IBAction)  start_button_pressed{
	
	
	if(toggle)
	{
		[m_pLongMusicPlayer play];
		toggle = NO;
		[actSpinner startAnimating];
		[btnStart setTitle:@"Stop Recording" forState: UIControlStateNormal ];	
		btnPlay.enabled = toggle;
		btnPlay.hidden = !toggle;
		
		//[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
		NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
		[recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];		
		//录音使用的苹果无损格式
		[recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleLossless] forKey:AVFormatIDKey];
		//设置采样率为44100hz
		[recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
		//设置录音的通道数目
		[recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
		//设置位深
		[recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
		//设置格式是否为大字节序编码
		[recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
		//设置音频格式是否位浮点型
		[recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
		//Encoder Settings (Only necessary if you want to change it.) 
		[recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey]; 
		[recordSetting setValue:[NSNumber numberWithInt:96] forKey:AVEncoderBitRateKey]; 
		[recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVEncoderBitDepthHintKey];
		[recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVSampleRateConverterAudioQualityKey];
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);//获得存储路径，
		NSString *documentDirectory = [paths objectAtIndex:0];//获得路径的第0个元素
		
		recordedTmpFile = [NSURL fileURLWithPath:[documentDirectory stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.%@", @"a", @"caf"]]];
		NSLog(@"Using File called: %@",recordedTmpFile);
		
		recorder = [[ AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error];
		
		[recorder setDelegate:self];

		[recorder prepareToRecord];
	
		[recorder record];

	}
	else
	{
		[m_pLongMusicPlayer stop];
		toggle = YES;
		[actSpinner stopAnimating];
		[btnStart setTitle:@"Start Recording" forState:UIControlStateNormal ];
		btnPlay.enabled = toggle;
		btnPlay.hidden = !toggle;
		
		NSLog(@"Using File called: %@",recordedTmpFile);
		//Stop the recorder.
		[recorder stop];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

-(IBAction) play_button_pressed{
	
	//The play button was pressed... 
	//Setup the AVAudioPlayer to play the file that we just recorded.
	AVAudioPlayer * avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordedTmpFile error:&error];
	[avPlayer prepareToPlay];
	[avPlayer play];
	
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	//Clean up the temp file.
	NSFileManager * fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:[recordedTmpFile path] error:&error];
	//Call the dealloc on the remaining objects.
	[recorder dealloc];
	recorder = nil;
	recordedTmpFile = nil;
}


- (void)dealloc {
	[super dealloc];
}


@end
