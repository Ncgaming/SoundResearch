//
//  AppSettings.m
//  MiKey
//
//  Created by Seng Hin Mak on 18/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "AppSettings.h"

#import "SynthesizeSingleton.h"

#define TOTAL_FILE_NUM @"totalFileNum"


@implementation AppSettings
@synthesize totalFileNum = _totalFileNum;

SYNTHESIZE_SINGLETON_FOR_CLASS(AppSettings)

+(AppSettings*)get 
{
    return [AppSettings sharedAppSettings];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        [self addObserver:self 
               forKeyPath:TOTAL_FILE_NUM 
                  options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld 
                  context:nil];
            
        _totalFileNum = 0;
        id totalFileNum1 = [[NSUserDefaults standardUserDefaults] objectForKey:TOTAL_FILE_NUM];
        if (totalFileNum1 != nil)
        {
            _totalFileNum = [[NSUserDefaults standardUserDefaults] integerForKey:TOTAL_FILE_NUM];
        }
        
    }
    return self;
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:TOTAL_FILE_NUM]) 
    {
        [[NSUserDefaults standardUserDefaults] setInteger:_totalFileNum forKey:TOTAL_FILE_NUM];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TotalFileNumChanged" object:nil];
    }
}




@end
