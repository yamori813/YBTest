//
//  YBTestAppDelegate.m
//  YBTest
//
//  Created by Hiroki Mori on 14/01/29.
//  Copyright 2014 Hiroki Mori. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "YBTestAppDelegate.h"

#include "json.h"

@implementation YBTestAppDelegate

@synthesize window;
@synthesize view;

- (NSString*)md5:(NSData *)dat
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( dat.bytes, dat.length, result ); // This is the md5 call
    return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];  
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
	xmlcont = @"";
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	xmlcont = [xmlcont stringByAppendingString:string];
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"Sid"]) {
		Sid = [NSString stringWithString:xmlcont];
	}
	if ([elementName isEqualToString:@"RootUniqId"]) {
		RootUniqId = [NSString stringWithString:xmlcont];
	}
}

- (NSString *)userinfo:(NSString *)rt
{
	// http://developer.yahoo.co.jp/yconnect/userinfo.html

	NSURL *url = [NSURL URLWithString:@"https://userinfo.yahooapis.jp/yconnect/v1/attribute?schema=openid"];

	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	[req setValue:[NSString stringWithFormat:@"Bearer %@", rt] forHTTPHeaderField:@"Authorization"];
	
	NSURLResponse *resp;
	
	NSError *err;
	
	NSData *result = [NSURLConnection sendSynchronousRequest:req
										   returningResponse:&resp
													   error:&err];
	
	NSString *resstr = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
	NSLog(@"%@", resstr);

	struct json_tokener* tok;
	struct json_object *new_obj;
	tok = json_tokener_new();
	new_obj = json_tokener_parse_ex(tok, [resstr UTF8String], [resstr length]);
//	printf("new_obj.to_string()=%s\n", json_object_to_json_string(new_obj));
	struct json_object *j_id = json_object_object_get(new_obj,"user_id");
	NSLog(@"%s",json_object_to_json_string(j_id));
	NSString *userid = [NSString stringWithCString:json_object_to_json_string(j_id) encoding:NSUTF8StringEncoding];
	return [userid substringWithRange:NSMakeRange(1, [userid length] - 2)];
}

- (void)fullinfo:(NSString *)rt userid:(NSString *)userid
{
	// http://developer.yahoo.co.jp/webapi/box/box/v1/userinfo.html
	NSURL *url = [NSURL URLWithString:
				  [NSString stringWithFormat:@"https://ybox.yahooapis.jp/v1/user/fullinfo/%@", userid]];

	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	[req setValue:[NSString stringWithFormat:@"Bearer %@", rt] forHTTPHeaderField:@"Authorization"];
	
	NSURLResponse *resp;
	
	NSError *err;
	
	NSData *result = [NSURLConnection sendSynchronousRequest:req
										   returningResponse:&resp
													   error:&err];
	
	NSLog(@"%@", [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding]);	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:result];
	[parser setDelegate:self];
	[parser parse];
}

- (void)filelist:(NSString *)rt sid:(NSString *)sid uniqid:(NSString *)uniqid
{
	// http://developer.yahoo.co.jp/webapi/box/box/v1/filelist.html
	NSURL *url = [NSURL URLWithString:
				  [NSString stringWithFormat:@"https://ybox.yahooapis.jp/v1/filelist/%@/%@", sid, uniqid]];
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	[req setValue:[NSString stringWithFormat:@"Bearer %@", rt] forHTTPHeaderField:@"Authorization"];
	
	NSURLResponse *resp;
	
	NSError *err;
	
	NSData *result = [NSURLConnection sendSynchronousRequest:req
										   returningResponse:&resp
													   error:&err];
	
	NSLog(@"%@", [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding]);	
}

- (void)upload:(NSString *)rt sid:(NSString *)sid uniqid:(NSString *)uniqid
{
	// http://developer.yahoo.co.jp/webapi/box/box/v1/upload.html
	NSURL *url = [NSURL URLWithString:@"https://upload.ybox.yahooapis.jp/v1/upload"];
	
	NSString *str = @"upad test";
	NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	[req setValue:[NSString stringWithFormat:@"Bearer %@", rt] forHTTPHeaderField:@"Authorization"];

	[req setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"content-length"];
	[req setValue:sid forHTTPHeaderField:@"box-obj-sid"];
	[req setValue:uniqid forHTTPHeaderField:@"box-obj-parentuniqid"];
	[req setValue:@"ybtest.txt" forHTTPHeaderField:@"box-obj-filename"];
	[req setValue:[self md5:data] forHTTPHeaderField:@"box-obj-md5"];
	
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:data];
	
	NSURLResponse *resp;
	
	NSError *err;
	
	NSData *result = [NSURLConnection sendSynchronousRequest:req
										   returningResponse:&resp
													   error:&err];
	
	NSLog(@"%@", [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding]);	
}

- (void)processNotification:(NSNotification *)notification
{
	
	WebView* wv = [notification object];
	
	NSString *urlstr = [wv mainFrameURL];
	NSLog(@"%@", urlstr);
	NSRange pos = [urlstr rangeOfString:@"#"];
	
	if((int)pos.location != -1) {
		NSString *rdurl = [urlstr substringToIndex:pos.location];
		if([rdurl isEqualToString:YJDN_CALLBACK] == YES) {
			NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
			[nc removeObserver:self
						  name:WebViewProgressEstimateChangedNotification
						object:nil];
		}
	} else {
		return;
	}
	NSString *query = [urlstr substringFromIndex:pos.location+1];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
	
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0]
						 stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1]
						 stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
        [dict setObject:val forKey:key];
    }
	
	NSString *userid = [self userinfo:[dict objectForKey:@"access_token"]];
	[self fullinfo:[dict objectForKey:@"access_token"] userid:userid];
	[self filelist:[dict objectForKey:@"access_token"]
			   sid:Sid uniqid:RootUniqId];
	[self upload:[dict objectForKey:@"access_token"]
			   sid:Sid uniqid:RootUniqId];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	// Insert code here to initialize your application 
	NSString *appid = YJDN_APPID;
	NSString *rdurl = YJDN_CALLBACK;
	NSString *state = @"morimori";
	NSString *nonce;
	
	// http://developer.yahoo.co.jp/yconnect/client_app/implicit/authorization.html
	int randomNumber = arc4random();
	nonce = [NSString stringWithFormat:@"%x", randomNumber];

	NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
	[param setObject:@"touch" forKey:@"display"];
	[param setObject:@"token+id_token" forKey:@"response_type"];
	[param setObject:appid forKey:@"client_id"];
	[param setObject:state forKey:@"state"];
//	[param setObject:@"simple" forKey:@"display"];
	[param setObject:rdurl forKey:@"redirect_uri"];
	[param setObject:@"openid" forKey:@"scope"];
	[param setObject:nonce forKey:@"nonce"];


	NSMutableString *paramstr = [NSMutableString string];
    
    NSString *key;
    for ( key in param ) {
		/*
		NSString *encval = (NSString *)CFURLCreateStringByAddingPercentEscapes(
																			   kCFAllocatorDefault,
																			   (CFStringRef)[param objectForKey:key],
																			   NULL,
																			   CFSTR(":/?#[]@!$&'()*,+;="),
																			   kCFStringEncodingUTF8 );
		
		[paramstr appendFormat:@"%@=%@&", key, encval];
		 */
        [paramstr appendFormat:@"%@=%@&", key, [param objectForKey:key]];
    }
	
	if ( [paramstr length] > 0 ) {
        [paramstr deleteCharactersInRange:NSMakeRange([paramstr length]-1, 1)];
    }

	NSString *urlstr = [NSString stringWithFormat:
						@"https://auth.login.yahoo.co.jp/yconnect/v1/authorization?%@", paramstr];

	[[view mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlstr]]];
    
	[nc addObserver:self
		   selector:@selector(processNotification:)
			   name:WebViewProgressEstimateChangedNotification
			 object:nil];
}

@end
