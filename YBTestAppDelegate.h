//
//  YBTestAppDelegate.h
//  YBTest
//
//  Created by Hiroki Mori on 14/01/29.
//  Copyright 2014 Hiroki Mori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <CoreFoundation/CFURL.h>

#define YJDN_APPID @"Please get your own appid on YJDN site"
#define YJDN_CALLBACK @"http://developer.yahoo.co.jp/start/"

@interface YBTestAppDelegate : NSObject <NSApplicationDelegate, NSXMLParserDelegate> {
	NSWindow *window;
	WebView *view;
	NSString *xmlcont;
	NSString *Sid;
	NSString *RootUniqId;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, nonatomic) IBOutlet WebView *view;

@end
