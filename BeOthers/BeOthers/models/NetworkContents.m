//
//  NetworkContents.m
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "NetworkContents.h"
#import "NetworkConfiguration.h"
#import "AFHTTPClient.h"
#import "NSString+SBJSON.h"
#import "AFHTTPRequestOperation.h"
#import "ZipArchive.h"
#import "Document.h"
#import "marcoHelper.h"


@implementation NetworkContents

+ (void)checkNewZipFile
{
    [self queryContentVersionCompleted:^(int version, NSString *zipPath) {
        DLog(@"latest zip version: %d", version);
        int lastDownloadVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastDownloadVersion"];
        DLog(@"saved zip version: %d", lastDownloadVersion);
        if (version > lastDownloadVersion)
        {
            DLog(@"Please download new zip");
            
            DLog(@"zip path? %@", zipPath);
            
            [self downloadZipFileFromPath:zipPath];
            
            
            [[NSUserDefaults standardUserDefaults] setInteger:version forKey:@"lastDownloadVersion"];
			[[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];
}

+ (void)downloadZipFileFromPath:(NSString*)webPath
{
    DLog(@"start download file.");
    NSURL *url = [NSURL URLWithString:webPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest: request];
    
    NSString *path = [[Document documentsDirectory] stringByAppendingPathComponent:@"content.zip"];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        DLog(@"Successfully downloaded content zip file to %@", path);
        
        ZipArchive *za = [[ZipArchive alloc] init];
        if ([za UnzipOpenFile:path])
        {
            BOOL success = [za UnzipFileTo:[Document documentsDirectory] overWrite:YES];
            
            if (success)
            {
                DLog(@"Successfully unzip file.");
            }
            else 
            {
                DLog(@"Got ERROR when unzip content.zip.");
            }
            [za UnzipCloseFile];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"Error downloading content file: %@", error);
    }];
    
    [operation start];
}

+ (void)queryContentVersionCompleted:(void (^)(int version, NSString *zipPath))block
{
    NSURL *baseURL = [NSURL URLWithString:BASE_URL];
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:baseURL];
    [client getPath:ZIP_VERSION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DLog(@"operation: %@", operation);
        NSString *responseStr = [NSString stringWithUTF8String:[responseObject bytes]];
        NSDictionary *response = [responseStr JSONValue];        
        DLog(@"%@", responseStr);
        DLog(@"%@", response);
        DLog(@"%@", [response objectForKey:@"zip_url"]);
        block([[response objectForKey:@"version"] intValue], [response objectForKey:@"zip_url"]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"Error fetching zip information. Error: %@", error);
    }];    
}

@end
