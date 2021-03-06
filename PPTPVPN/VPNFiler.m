//
//  VPNFiler.m
//  PPTPVPN
//
//  Created by chen on 2018/8/6.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//  https://github.com/iHongRen/pptp-vpn

#import "VPNFiler.h"

NSString *const PPTPVPNFileDirectory = @"/etc/ppp/peers";
NSString *const PPTPVPNConfigFileName = @"this_is_a_pptp_vpn_config_file_0";
NSString *const PPTPVPNLogFile = @"/tmp/pptp_vpn_log.txt";;

@implementation VPNFiler

+ (NSString*)VPNFilePath {
    return [PPTPVPNFileDirectory stringByAppendingPathComponent: PPTPVPNConfigFileName];
}

+ (BOOL)createVPNFileDirectoryIfNeed {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isExistFile = [fileManager fileExistsAtPath:PPTPVPNFileDirectory isDirectory:&isDir];
    
    if(isExistFile && isDir) {
        return YES;
    }
    
    return [fileManager createDirectoryAtPath:PPTPVPNFileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
}

+ (BOOL)createVPNFileIfNeed {
    if(![self createVPNFileDirectoryIfNeed]) {
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExistFile = [fileManager fileExistsAtPath:[self VPNFilePath]];
    
    if(isExistFile) {
        return YES;
    }
    
    return [fileManager createFileAtPath:[self VPNFilePath] contents:nil attributes:nil];
}

/**
 --- config ---
 remoteaddress \"vpn.ihongren.com\"\n\
 user \"ihongren\"\n\
 password \"12345678\"\n\
*/
+ (void)writeVPNFileHost:(NSString*)remoteaddress
                    user:(NSString*)user
                password:(NSString*)password
                   block:(void(^)(NSError *error))complete {
    if(![self createVPNFileIfNeed]) {
        NSError *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:nil];
        complete(err);
        return;
    }
    
    NSString *_remoteaddress = [NSString stringWithFormat:@"remoteaddress \"%@\"\n",remoteaddress?:@""];
    NSString *_user = [NSString stringWithFormat:@"user \"%@\"\n",user?:@""];
    NSString *_password = [NSString stringWithFormat:@"password \"%@\"\n",password?:@""];
    NSString *logfile = [NSString stringWithFormat:@"logfile %@", PPTPVPNLogFile];
    NSString *vpnConfig = [NSString stringWithFormat:@"%@%@%@%@",_remoteaddress,_user,_password, logfile];
    
    NSError *err;
    NSString *script = [vpnConfig stringByAppendingString:[self VPNFileOtherScript]];
    
    [script writeToFile:[self VPNFilePath] atomically:YES encoding:NSUTF8StringEncoding error:&err];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        !complete?:complete(err);
    });
}

// https://github.com/davidjosefson/lex-integrity-mac
+ (NSString*)VPNFileOtherScript {
    return
@"## Other settings\n\
plugin PPTP.ppp\n\
noauth\n\
redialcount 1\n\
redialtimer 5\n\
idle 1800\n\
mru 1436\n\
mtu 1436\n\
receive-all\n\
novj 0:0\n\
ipcp-accept-local\n\
ipcp-accept-remote\n\
refuse-eap\n\
refuse-pap\n\
refuse-chap-md5\n\
hide-password\n\
looplocal\n\
nodetach\n\
ms-dns 8.8.8.8\n\
usepeerdns\n\
debug\n\
defaultroute";
}
@end
