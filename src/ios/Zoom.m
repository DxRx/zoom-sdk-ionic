/**
 *  Zoom.m
 *
 *  @author Zoom Video Communications, Inc.
 *  @version v4.6.21666.0512
 */

#import "Zoom.h"


#define kSDKDomain  @"https://zoom.us"
#define DEBUG   YES

@implementation Zoom

- (void)initialize:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variables.
    NSString* appKey = [command.arguments objectAtIndex:0];
    NSString* appSecret = [command.arguments objectAtIndex:1];

    // Run authentication and initialize SDK on main thread.
    dispatch_async(dispatch_get_main_queue(), ^(void){
        // if input parameters are not valid.
        if (appKey == nil || ![appKey isKindOfClass:[NSString class]] || [appKey length] == 0 || appSecret == nil || ![appSecret isKindOfClass:[NSString class]]|| [appSecret length] == 0) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Please pass valid SDK key and secret."];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }

        // Initialize SDK.
        MobileRTCSDKInitContext *context = [[MobileRTCSDKInitContext alloc] init];
        context.domain = kSDKDomain;
        context.enableLog = YES;
        context.locale = MobileRTC_ZoomLocale_Default;
        context.appGroupId = @"group.riahealth";

        BOOL initRet = [[MobileRTC sharedRTC] initialize:context];

        // If the SDK has successfully authorized, avoid re-authorization.
        if ([[MobileRTC sharedRTC] isRTCAuthorized])
        {
            return;
        }

        // Get auth service.
        MobileRTCAuthService *authService = [[MobileRTC sharedRTC] getAuthService];
        if (authService)
        {
            // Assign delegate.
            authService.delegate = self;
            // Assign key and secret.
            authService.clientKey = appKey;
            authService.clientSecret = appSecret;
            // Perform SDK auth.
            [authService sdkAuth];
        }
    });
}

- (void)initializeWithJwt:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variable
    NSString* jwt = [command.arguments objectAtIndex:0];

    // Run authentication and initialize SDK on main thread.
    dispatch_async(dispatch_get_main_queue(), ^(void){
        // if input parameters are not valid.
        if (jwt == nil || ![jwt isKindOfClass:[NSString class]] || [jwt length] == 0 ) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Please pass valid jwt."];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }

        // Initialize SDK.
        MobileRTCSDKInitContext *context = [[MobileRTCSDKInitContext alloc] init];
        context.domain = kSDKDomain;
        context.enableLog = YES;
        context.locale = MobileRTC_ZoomLocale_Default;
        context.appGroupId = @"group.riahealth";

        BOOL initRet = [[MobileRTC sharedRTC] initialize:context];

        // If the SDK has successfully authorized, avoid re-authorization.
        if ([[MobileRTC sharedRTC] isRTCAuthorized])
        {
            return;
        }

        // Get auth service.
        MobileRTCAuthService *authService = [[MobileRTC sharedRTC] getAuthService];
        if (authService)
        {
            // Auth step
            // Assign delegate.
            authService.delegate = self;
            // Assign key and secret.
            authService.jwtToken = jwt;
            // Perform SDK auth.
            [authService sdkAuth];
        }
    });
}

- (void)logout:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Run logout method on main thread.
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        // Try to log user out
        if (![[[MobileRTC sharedRTC] getAuthService] isLoggedIn]) {
            NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
            res[@"result"] = @NO;
            res[@"message"] = @"You are not logged in.";
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:res];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
        [[[MobileRTC sharedRTC] getAuthService] logoutRTC];
    });
}

- (void)isLoggedIn:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Check whether user is logged in.
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        MobileRTCAuthService* authService = [[MobileRTC sharedRTC] getAuthService];
        if (authService != nil) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[authService isLoggedIn]];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    });
}

- (void)joinMeeting:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variables.
    NSString* meetingNo = [command.arguments objectAtIndex:0];
    NSString* meetingPassword = [command.arguments objectAtIndex:1];
    NSString* displayName = [command.arguments objectAtIndex:2];
    NSDictionary* options = [command.arguments objectAtIndex:3];

    if (DEBUG) {
        NSLog(@"========meeting number======= %@", meetingNo);
        NSLog(@"========display name======= %@", displayName);
        NSLog(@"========meeting options===== %@", options);
    }
    // Meeting number regular expression.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{8,11}" options:0 error:nil];
    UIViewController *rootVC = [self topMostController];
    // UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:rootVC];

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (meetingNo == nil || ![meetingNo isKindOfClass:[NSString class]] || [meetingNo length] == 0 || [regex numberOfMatchesInString:meetingNo options:0 range:NSMakeRange(0, [meetingNo length])] == 0|| displayName == nil || ![displayName isKindOfClass:[NSString class]] || [displayName length] == 0) {
            NSLog(@"Please enter valid meeting number and display name");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Please enter valid meeting number and display name"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }
        // Get meeting service
        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
        if (ms != nil)
        {
            // Assign delegate.
            ms.delegate = self;
            [[MobileRTC sharedRTC] setMobileRTCRootController:rootVC.navigationController];
            // Meeting options
	    
	    // just internet calling
            if ([options objectForKey:@"internet_audio"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] setAutoConnectInternetAudio:[options[@"internet_audio"] boolValue]];
            }
	    
            // custom_meeting_id
            if ([options objectForKey:@"custom_meeting_id"] != [NSNull null]) {
                NSString* customMeetingId = options[@"custom_meeting_id"];
                [ms customizeMeetingTitle:customMeetingId];
            }
            // no_audio
            if ([options objectForKey:@"no_audio"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteAudioWhenJoinMeeting:[options[@"no_audio"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteAudioWhenJoinMeeting:NO];
            }
            // no_bottom_toolbar
            if ([options objectForKey:@"no_bottom_toolbar"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].bottomBarHidden = [options[@"no_bottom_toolbar"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].bottomBarHidden = NO;
            }
            // no_dial_in_via_phone
            if ([options objectForKey:@"no_dial_in_via_phone"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallIn: [options[@"no_dial_in_via_phone"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallIn: NO];
            }
            // no_dial_out_to_phone
            if ([options objectForKey:@"no_dial_out_to_phone"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallOut: [options[@"no_dial_out_to_phone"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallOut:NO];
            }
            // no_disconnect_audio
            if ([options objectForKey:@"no_disconnect_audio"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings ].disconnectAudioHidden = [options[@"no_disconnect_audio"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings ].disconnectAudioHidden = NO;
            }
            
            // no_driving_mode
            if ([options objectForKey:@"no_driving_mode"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableDriveMode: [options[@"no_driving_mode"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableDriveMode:NO];
            }
            // no_invite
            if ([options objectForKey:@"no_invite"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingInviteHidden = [options[@"no_invite"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingInviteHidden = NO;
            }
            
            // no_titlebar
            if ([options objectForKey:@"no_titlebar"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].topBarHidden = [options[@"no_titlebar"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].topBarHidden = NO;
            }
            
            // no_video
            if ([options objectForKey:@"no_video"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteVideoWhenJoinMeeting:[options[@"no_video"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteVideoWhenJoinMeeting:NO];
            }
            
            // no_button_video
            if ([options objectForKey:@"no_button_video"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingVideoHidden = [options[@"no_button_video"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingVideoHidden = NO;
            }
            // no_button_audio
            if ([options objectForKey:@"no_button_audio"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingAudioHidden = [options[@"no_button_audio"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingAudioHidden = NO;
            }
            // no_button_share
            if ([options objectForKey:@"no_button_share"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingShareHidden = [options[@"no_button_share"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingShareHidden = NO;
            }
            // no_button_participants
            if ([options objectForKey:@"no_button_participants"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingParticipantHidden = [options[@"no_button_participants"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingParticipantHidden = NO;
            }
            // no_button_more
            if ([options objectForKey:@"no_button_more"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingMoreHidden = [options[@"no_button_more"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingMoreHidden = NO;
            }
            // no_text_meeting_id
            if ([options objectForKey:@"no_text_meeting_id"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingTitleHidden = [options[@"no_text_meeting_id"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingTitleHidden = NO;
            }
            // no_text_password
            if ([options objectForKey:@"no_text_password"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingPasswordHidden = [options[@"no_text_password"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingPasswordHidden = NO;
            }
            // no_button_leave
            if ([options objectForKey:@"no_button_leave"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingLeaveHidden = [options[@"no_button_leave"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingLeaveHidden = NO;
            }
            NSString* participantID = @"";
            // participant_id
            if ([options objectForKey:@"participant_id"] != [NSNull null]) {
                participantID = options[@"participant_id"];
            }
            // Prepare meeting parameters.
            MobileRTCMeetingJoinParam *joinParams = [[MobileRTCMeetingJoinParam alloc] init];
            joinParams.meetingNumber = meetingNo;
            joinParams.password = meetingPassword;
            joinParams.userName = displayName;
            joinParams.customerKey = participantID;

            // Join meeting.
            MobileRTCMeetError response = [ms joinMeetingWithJoinParam:joinParams];
            if (DEBUG) {
                NSLog(@"Join a Meeting res:%d", response);
            }
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Joined"];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    });
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

- (void)startMeeting:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variables.
    NSString* meetingNo = [command.arguments objectAtIndex:0];
    NSString* displayName = [command.arguments objectAtIndex:1];
    NSString* zoomToken = [command.arguments objectAtIndex:2];
    NSString* zoomAccessToken = [command.arguments objectAtIndex:3];
    NSString* userId = [command.arguments objectAtIndex:4];
    NSDictionary* options = [command.arguments objectAtIndex:5];

    dispatch_async(dispatch_get_main_queue(), ^(void) {

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{8,11}" options:0 error:nil];

        if (meetingNo == nil || ![meetingNo isKindOfClass:[NSString class]] || [meetingNo length] == 0 || [regex numberOfMatchesInString:meetingNo options:0 range:NSMakeRange(0, [meetingNo length])] == 0) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Please enter valid meeting number"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }

        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
        if (ms)
        {
            // Assign delegate.
            ms.delegate = self;
            // Meeting options
            // custom_meeting_id
            if ([options objectForKey:@"custom_meeting_id"] != [NSNull null]) {
                NSString* customMeetingId = options[@"custom_meeting_id"];
                [ms customizeMeetingTitle:customMeetingId];
            }
            // no_bottom_toolbar
            if ([options objectForKey:@"no_bottom_toolbar"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].bottomBarHidden = [options[@"no_bottom_toolbar"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].bottomBarHidden = NO;
            }
            // no_dial_in_via_phone
            if ([options objectForKey:@"no_dial_in_via_phone"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallIn: [options[@"no_dial_in_via_phone"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallIn: NO];
            }
            // no_dial_out_to_phone
            if ([options objectForKey:@"no_dial_out_to_phone"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallOut: [options[@"no_dial_out_to_phone"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallOut:NO];
            }
            // no_disconnect_audio
            if ([options objectForKey:@"no_disconnect_audio"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings ].disconnectAudioHidden = [options[@"no_disconnect_audio"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings ].disconnectAudioHidden = NO;
            }
            // no_driving_mode
            if ([options objectForKey:@"no_driving_mode"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableDriveMode: [options[@"no_driving_mode"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableDriveMode:NO];
            }
            // no_invite
            if ([options objectForKey:@"no_invite"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingInviteHidden = [options[@"no_invite"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingInviteHidden = NO;
            }
            // no_titlebar
            if ([options objectForKey:@"no_titlebar"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].topBarHidden = [options[@"no_titlebar"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].topBarHidden = NO;
            }
            // no_audio
            if ([options objectForKey:@"no_audio"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteAudioWhenJoinMeeting:[options[@"no_audio"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteAudioWhenJoinMeeting:NO];
            }
            // no_video
            if ([options objectForKey:@"no_video"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteVideoWhenJoinMeeting:[options[@"no_video"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteVideoWhenJoinMeeting:NO];
            }
            // no_button_video
            if ([options objectForKey:@"no_button_video"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingVideoHidden = [options[@"no_button_video"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingVideoHidden = NO;
            }
            // no_button_audio
            if ([options objectForKey:@"no_button_audio"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingAudioHidden = [options[@"no_button_audio"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingAudioHidden = NO;
            }
            // no_button_share
            if ([options objectForKey:@"no_button_share"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingShareHidden = [options[@"no_button_share"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingShareHidden = NO;
            }
            // no_button_participants
            if ([options objectForKey:@"no_button_participants"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingParticipantHidden = [options[@"no_button_participants"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingParticipantHidden = NO;
            }
            // no_button_more
            if ([options objectForKey:@"no_button_more"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingMoreHidden = [options[@"no_button_more"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingMoreHidden = NO;
            }
            // no_text_meeting_id
            if ([options objectForKey:@"no_text_meeting_id"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingTitleHidden = [options[@"no_text_meeting_id"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingTitleHidden = NO;
            }
            // no_text_password
            if ([options objectForKey:@"no_text_password"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingPasswordHidden = [options[@"no_text_password"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingPasswordHidden = NO;
            }
            // no_button_leave
            if ([options objectForKey:@"no_button_leave"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingLeaveHidden = [options[@"no_button_leave"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingLeaveHidden = NO;
            }
            // Prepare start meeting param.
            MobileRTCMeetingStartParam * param = nil;

            if ([[[MobileRTC sharedRTC] getAuthService] isLoggedIn])
            {
                // Is user is logged in.
                NSLog(@"start meeting with logged in.");
                MobileRTCMeetingStartParam4LoginlUser * user = [[MobileRTCMeetingStartParam4LoginlUser alloc]init];
                user.isAppShare = NO;
                param = user;
                param.meetingNumber = meetingNo;
            }
            else
            {
                // Is user is not logged in.
                NSLog(@"Start meeting without logged in.");
                NSLog(@"zoom token: %@",zoomToken);
                NSLog(@"zak: %@",zoomAccessToken);
                if (zoomToken == nil || ![zoomToken isKindOfClass:[NSString class]] || [zoomToken length] == 0 ||
                    zoomAccessToken == nil || ![zoomAccessToken isKindOfClass:[NSString class]] || [zoomAccessToken length] == 0 ||
                    userId == nil || ![userId isKindOfClass:[NSString class]] || [userId length] == 0) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Your zoom token, zoom access token, and userId are not valid"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                    return;
                }

                MobileRTCMeetingStartParam4WithoutLoginUser * user = [[MobileRTCMeetingStartParam4WithoutLoginUser alloc]init];
                user.userType = MobileRTCUserType_APIUser;
                user.meetingNumber = meetingNo;
                user.userName = displayName;
                // user.userToken = zoomToken;
                // user.userID = userId;
                user.isAppShare = NO;
                user.zak = zoomAccessToken;
                param = user;
            }
            // participant_id
            if ([options objectForKey:@"participant_id"] != [NSNull null]) {
                param.customerKey = options[@"participant_id"];
            }
            // Start meeting.
            MobileRTCMeetError response = [ms startMeetingWithStartParam:param];
            if (DEBUG) {
                NSLog(@"start a meeting res:%d", response);
            }
        }
    });
}

- (void)startInstantMeeting:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    NSDictionary* options = [command.arguments objectAtIndex:0];

    dispatch_async(dispatch_get_main_queue(), ^(void) {

        if (![[[MobileRTC sharedRTC] getAuthService] isLoggedIn]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"You are not logged in"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }
        // Get meeting service.
        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];

        if (ms)
        {
            // Assign delegate.
            ms.delegate = self;
            // Meeting options
            // custom_meeting_id
            if ([options objectForKey:@"custom_meeting_id"] != [NSNull null]) {
                NSString* customMeetingId = options[@"custom_meeting_id"];
                [ms customizeMeetingTitle:customMeetingId];
            }
            // no_audio
            if ([options objectForKey:@"no_audio"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteAudioWhenJoinMeeting:[options[@"no_audio"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteAudioWhenJoinMeeting:NO];
            }
            // no_bottom_toolbar
            if ([options objectForKey:@"no_bottom_toolbar"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].bottomBarHidden = [options[@"no_bottom_toolbar"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].bottomBarHidden = NO;
            }
            // no_dial_in_via_phone
            if ([options objectForKey:@"no_dial_in_via_phone"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallIn: [options[@"no_dial_in_via_phone"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallIn: NO];
            }
            // no_dial_out_to_phone
            if ([options objectForKey:@"no_dial_out_to_phone"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallOut: [options[@"no_dial_out_to_phone"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableCallOut:NO];
            }
            // no_disconnect_audio
            if ([options objectForKey:@"no_disconnect_audio"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings ].disconnectAudioHidden = [options[@"no_disconnect_audio"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings ].disconnectAudioHidden = NO;
            }
            
            // no_driving_mode
            if ([options objectForKey:@"no_driving_mode"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableDriveMode: [options[@"no_driving_mode"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] disableDriveMode:NO];
            }
            // no_invite
            if ([options objectForKey:@"no_invite"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingInviteHidden = [options[@"no_invite"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingInviteHidden = NO;
            }
            
            // no_titlebar
            if ([options objectForKey:@"no_titlebar"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].topBarHidden = [options[@"no_titlebar"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].topBarHidden = NO;
            }
            
            // no_video
            if ([options objectForKey:@"no_video"] != [NSNull null]) {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteVideoWhenJoinMeeting:[options[@"no_video"] boolValue]];
            } else {
                [[[MobileRTC sharedRTC] getMeetingSettings] setMuteVideoWhenJoinMeeting:NO];
            }
            
            // no_button_video
            if ([options objectForKey:@"no_button_video"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingVideoHidden = [options[@"no_button_video"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingVideoHidden = NO;
            }
            // no_button_audio
            if ([options objectForKey:@"no_button_audio"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingAudioHidden = [options[@"no_button_audio"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingAudioHidden = NO;
            }
            // no_button_share
            if ([options objectForKey:@"no_button_share"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingShareHidden = [options[@"no_button_share"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingShareHidden = NO;
            }
            // no_button_participants
            if ([options objectForKey:@"no_button_participants"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingParticipantHidden = [options[@"no_button_participants"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingParticipantHidden = NO;
            }
            // no_button_more
            if ([options objectForKey:@"no_button_more"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingMoreHidden = [options[@"no_button_more"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingMoreHidden = NO;
            }
            // no_text_meeting_id
            if ([options objectForKey:@"no_text_meeting_id"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingTitleHidden = [options[@"no_text_meeting_id"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingTitleHidden = NO;
            }
            // no_text_password
            if ([options objectForKey:@"no_text_password"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingPasswordHidden = [options[@"no_text_password"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingPasswordHidden = NO;
            }
            // no_button_leave
            if ([options objectForKey:@"no_button_leave"] != [NSNull null]) {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingLeaveHidden = [options[@"no_button_leave"] boolValue];
            } else {
                [[MobileRTC sharedRTC] getMeetingSettings].meetingLeaveHidden = NO;
            }
            // Prepare start meeting parameters.
            MobileRTCMeetingJoinParam *joinParams = [[MobileRTCMeetingJoinParam alloc] init];
            // Join meeting.
            MobileRTCMeetError response = [ms joinMeetingWithJoinParam:joinParams];
            if (DEBUG) {
                NSLog(@"start an instant meeting res:%d", response);
            }
        }
    });
}

- (void)setLocale:(CDVInvokedUrlCommand *)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variable
    NSString* languageTag = [command.arguments objectAtIndex:0];

    NSString* language = @"en";

    // Ugly way to unify language codes.
    if ([languageTag isEqualToString:@"en-US"]) {
        language = @"en";
    } else if ([languageTag isEqualToString:@"zh-CN"]) {
        language = @"zh-Hans";
    } else if ([languageTag isEqualToString:@"ja-JP"]) {
        language = @"ja";
    } else if ([languageTag isEqualToString:@"de-DE"]) {
        language = @"de";
    } else if ([languageTag isEqualToString:@"fr-FR"]) {
        language = @"fr";
    } else if ([languageTag isEqualToString:@"zh-TW"]) {
        language = @"zh-Hant";
    } else if ([languageTag isEqualToString:@"es-419"]) {
        language = @"es";
    } else if ([languageTag isEqualToString:@"ru-RU"]) {
        language = @"ru";
    } else if ([languageTag isEqualToString:@"pt-PT"]) {
        language = @"pt-PT";
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Language not supported"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (DEBUG) {
            NSLog(@"set language ===== %@", language);
            NSLog(@"Supported languages: %@", [[MobileRTC sharedRTC] supportedLanguages]);
        }
        // Set language
        [[MobileRTC sharedRTC] setLanguage:language];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Set language Successfully"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    });
}


- (void)onMobileRTCAuthReturn:(MobileRTCAuthError)returnValue
{
    if (DEBUG) {
        NSLog(@"onMobileRTCAuthReturn: %@", [self getAuthErrorMessage:returnValue]);
    }

    if (returnValue != MobileRTCAuthError_Success)
    {
        // Authentication error, please check error code.
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"SDK authentication failed, error: %@", @""), [self getAuthErrorMessage:returnValue]];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    } else {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Initialize successfully, return value: %@", @""), [self getAuthErrorMessage:returnValue]];
        NSLog(@"%@", message);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    }
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)onMobileRTCLoginReturn:(NSInteger)returnValue
{
    // 0 is success, otherwise is failed.
    if (DEBUG) {
        NSLog(@"onMobileRTCLoginReturn result=%zd", returnValue);
    }

    NSMutableDictionary *res = [[NSMutableDictionary alloc] init];

    if (returnValue == 0) {
        res[@"result"] = @YES;
        res[@"message"] = @"Successfully logged in";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:res];
    } else {
        res[@"result"] = @NO;
        res[@"message"] = @"ERROR! Failed to log in";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:res];
    }

    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)onMobileRTCLogoutReturn:(NSInteger)returnValue
{
    // 0 is success, otherwise is failed.
    if (DEBUG) {
       NSLog(@"onMobileRTCLogoutReturn result=%zd", returnValue);
    }

    NSMutableDictionary *res = [[NSMutableDictionary alloc] init];

    if (returnValue == 0) {
        res[@"result"] = @YES;
        res[@"message"] = @"Successfully logged out";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:res];
    } else {
        res[@"result"] = @NO;
        res[@"message"] = @"ERROR! Failed to log out";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:res];
    }

    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)onMeetingError:(MobileRTCMeetError)error message:(NSString*)message
{
    if (DEBUG) {
     NSLog(@"onMeetingError:%zd, message:%@", error, message);
    }
    if (error != MobileRTCMeetError_Success) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[self getMeetErrorMessage:error]];
    } else {
     pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self getMeetErrorMessage:error]];
    }
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)onMeetingReturn:(MobileRTCMeetError)error internalError:(NSInteger)internalError
{
    if (DEBUG) {
     NSLog(@"onMeetingError:%zd, message:%zd", error, internalError);
    }
    if (error != MobileRTCMeetError_Success) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[self getMeetErrorMessage:error]];
    } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self getMeetErrorMessage:error]];
    }
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)onMeetingEndedReason:(MobileRTCMeetingEndReason)reason
{
    if (DEBUG) {
     NSLog(@"onMeetingEndedReason:%zd", reason);
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self getMeetingEndedMessage:reason]];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (NSString *)getAuthErrorMessage:(MobileRTCAuthError)errorCode
{
    NSString* message = @"";
    switch (errorCode) {
        case MobileRTCAuthError_Success:
            message = @"Authentication success.";
            break;
        case MobileRTCAuthError_KeyOrSecretEmpty:
            message = @"SDK key or secret is empty.";
            break;
        case MobileRTCAuthError_KeyOrSecretWrong:
            message = @"SDK key or secret is wrong.";
            break;
        case MobileRTCAuthError_AccountNotSupport:
            message = @"Your account does not support SDK.";
            break;
        case MobileRTCAuthError_AccountNotEnableSDK:
            message = @"Your account does not support SDK.";
            break;
        case MobileRTCAuthError_Unknown:
            message = @"Unknown error.Please try again.";
            break;
        default:
            message = @"Unknown error.Please try again.";
            break;
    }
    return message;
}

- (NSString *)getMeetingEndedMessage:(MobileRTCMeetingEndReason)errorCode
{
    NSString* message = @"";

    switch (errorCode) {
        case MobileRTCMeetingEndReason_SelfLeave:
            message = @"Self left.";
            break;
        case MobileRTCMeetingEndReason_RemovedByHost:
            message = @"Removed by host.";
            break;
        case MobileRTCMeetingEndReason_EndByHost:
            message = @"Ended by host.";
            break;
        case MobileRTCMeetingEndReason_JBHTimeout:
            message = @"JBH Timout.";
            break;
        case MobileRTCMeetingEndReason_NoAteendee:
            message = @"No attendee.";
            break;
        case MobileRTCMeetingEndReason_HostEndForAnotherMeeting:
            message = @"Host ended for another meeting.";
            break;
        case MobileRTCMeetingEndReason_ConnectBroken:
            message = @"Connection broken.";
            break;
        default:
            message = @"Unknown error.Please try again.";
            break;
    }
    return message;
}

- (NSString *)getMeetErrorMessage:(MobileRTCMeetError)errorCode
{
    NSString * message = @"";
    switch (errorCode) {
        case MobileRTCMeetError_Success:
            message = @"Successfully start/join meeting.";
            break;
        case MobileRTCMeetError_NetworkError:
            message = @"Network issue, please check your network connection.";
            break;
        case MobileRTCMeetError_ReconnectError:
            message = @"Failed to reconnect to meeting.";
            break;
        case MobileRTCMeetError_MMRError:
            message = @"MMR issue, please check mmr configruation.";
            break;
        case MobileRTCMeetError_PasswordError:
            message = @"Meeting password incorrect.";
            break;
        case MobileRTCMeetError_SessionError:
            message = @"Failed to create a session with our sever.";
            break;
        case MobileRTCMeetError_MeetingOver:
            message = @"The meeting is over.";
            break;
        case MobileRTCMeetError_MeetingNotStart:
            message = @"The meeting does not start.";
            break;
        case MobileRTCMeetError_MeetingNotExist:
            message = @"The meeting does not exist.";
            break;
        case MobileRTCMeetError_MeetingUserFull:
            message = @"The meeting has reached a maximum of participants.";
            break;
        case MobileRTCMeetError_MeetingClientIncompatible:
            message = @"The Zoom SDK version is incompatible.";
            break;
        case MobileRTCMeetError_NoMMR:
            message = @"No mmr is available at this point.";
            break;
        case MobileRTCMeetError_MeetingLocked:
            message = @"The meeting is locked by the host.";
            break;
        case MobileRTCMeetError_MeetingRestricted:
            message = @"The meeting is restricted.";
            break;
        case MobileRTCMeetError_MeetingRestrictedJBH:
            message = @"The meeting does not allow join before host. Please try again later.";
            break;
        case MobileRTCMeetError_CannotEmitWebRequest:
            message = @"Failed to send create meeting request to server.";
            break;
        case MobileRTCMeetError_CannotStartTokenExpire:
            message = @"Failed to start meeting due to token exipred.";
            break;
        case MobileRTCMeetError_VideoError:
            message = @"The user's video cannot work.";
            break;
        case MobileRTCMeetError_AudioAutoStartError:
            message = @"The user's audio cannot auto start.";
            break;
        case MobileRTCMeetError_RegisterWebinarFull:
            message = @"The webinar has reached its maximum allowed participants.";
            break;
        case MobileRTCMeetError_RegisterWebinarHostRegister:
            message = @"Sign in to start the webinar.";
            break;
        case MobileRTCMeetError_RegisterWebinarPanelistRegister:
            message = @"Join the webinar from the link";
            break;
        case MobileRTCMeetError_RegisterWebinarDeniedEmail:
            message = @"The host has denied your webinar registration.";
            break;
        case MobileRTCMeetError_RegisterWebinarEnforceLogin:
            message = @"The webinar requires sign-in with specific account to join.";
            break;
        case MobileRTCMeetError_ZCCertificateChanged:
            message = @"The certificate of ZC has been changed. Please contact Zoom for further support.";
            break;
        case MobileRTCMeetError_VanityNotExist:
            message = @"The vanity does not exist";
            break;
        case MobileRTCMeetError_JoinWebinarWithSameEmail:
            message = @"The email address has already been register in this webinar.";
            break;
        case MobileRTCMeetError_WriteConfigFile:
            message = @"Failed to write config file.";
            break;
        case MobileRTCMeetError_RemovedByHost:
            message = @"You have been removed by the host.";
            break;
        case MobileRTCMeetError_InvalidArguments:
            message = @"Invalid arguments.";
            break;
        case MobileRTCMeetError_InvalidUserType:
            message = @"Invalid user type.";
            break;
        case MobileRTCMeetError_InAnotherMeeting:
            message = @"Already in another ongoing meeting.";
            break;
        case MobileRTCMeetError_Unknown:
            message = @"Unknown error.";
            break;
        default:
            message = @"Unknown error.";
            break;
    }
    return message;
}

@end
