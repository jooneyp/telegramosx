//
//  MessagesUtils.m
//  TelegramTest
//
//  Created by keepcoder on 04.11.13.
//  Copyright (c) 2013 keepcoder. All rights reserved.
//

#import "MessagesUtils.h"
#import "Extended.h"
#import "TMAttributedString.h"
#import "TMInAppLinks.h"

@implementation MessagesUtils

+(NSString *)serviceMessage:(TGMessage *)message forAction:(TGMessageAction *)action {
    
    TGUser *user = [[UsersManager sharedManager] find:message.from_id];
    NSString *text;
    if([action isKindOfClass:[TL_messageActionChatEditTitle class]]) {
        text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.ChangedGroupName", nil), [user fullName], action.title];
    } else if([action isKindOfClass:[TL_messageActionChatDeletePhoto class]]) {
        text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.RemovedGroupPhoto", nil), [user fullName]];
    } else if([action isKindOfClass:[TL_messageActionChatEditPhoto class]]) {
        text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.ChangedGroupPhoto", nil), [user fullName]];
    } else if([action isKindOfClass:[TL_messageActionChatAddUser class]]) {
        TGUser *userAdd = [[UsersManager sharedManager] find:action.user_id];
        if(action.user_id != message.from_id) {
            text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.InvitedGroup", nil), [user fullName], [userAdd fullName]];
        } else {
            text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.JoinedGroup", nil), [user fullName]];
        }
        text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.InvitedGroup", nil), [user fullName], [userAdd fullName]];
    }else if([action isKindOfClass:[TL_messageActionChatCreate class]]) {
        text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.CreatedChat", nil), [user fullName],action.title];
    } else if([action isKindOfClass:[TL_messageActionChatDeleteUser class]]) {
        
        
        if(action.user_id != message.from_id) {
            TGUser *userDelete = [[UsersManager sharedManager] find:action.user_id];
            text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.KickedGroup", nil), [user fullName], [userDelete fullName]];
        } else {
            text = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.ServiceMessage.LeftGroup", nil), [user fullName]];
        }
    } else if([action isKindOfClass:[TL_messageActionEncryptedChat class]]) {
        text = action.title;
    }
    return text;
}

+(NSString *)selfDestructTimer:(int)ttl {
    if(ttl == 0) {
        return NSLocalizedString(@"SelfDestruction.DisableTimer", nil);
    }
    
    if(ttl <= 2) {
        return [NSString stringWithFormat:NSLocalizedString(@"SelfDestruction.SetTimer", nil),NSLocalizedString(@"Notification.MessageLifetime2s", nil)];
    }
    
    if(ttl <= 5) {
        return [NSString stringWithFormat:NSLocalizedString(@"SelfDestruction.SetTimer", nil),NSLocalizedString(@"Notification.MessageLifetime5s", nil)];
    }
    
    if(ttl <= 60) {
        return [NSString stringWithFormat:NSLocalizedString(@"SelfDestruction.SetTimer", nil),NSLocalizedString(@"Notification.MessageLifetime1m", nil)];
    }
    
    if(ttl <= 60*60) {
        return [NSString stringWithFormat:NSLocalizedString(@"SelfDestruction.SetTimer", nil),NSLocalizedString(@"Notification.MessageLifetime1h", nil)];
    }
    
    if(ttl <= 60*60*24) {
        return [NSString stringWithFormat:NSLocalizedString(@"SelfDestruction.SetTimer", nil),NSLocalizedString(@"Notification.MessageLifetime1d", nil)];
    }
    
    if(ttl <= 60*60*24*7) {
        return [NSString stringWithFormat:NSLocalizedString(@"SelfDestruction.SetTimer", nil),NSLocalizedString(@"Notification.MessageLifetime1w", nil)];
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"SelfDestruction.SetRandomTimer", nil),ttl];
}


+(NSString *)shortTTL:(int)ttl {
    if(ttl == 0 || ttl == -1) {
        return NSLocalizedString(@"Secret.SelfDestruct.Off", nil);
    }
    
    if(ttl <= 2) {
        return NSLocalizedString(@"Secret.SelfDestruct.2s", nil);
    }
    
    if(ttl <= 5) {
        return NSLocalizedString(@"Secret.SelfDestruct.5s", nil);
    }
    
    if(ttl <= 60) {
        return NSLocalizedString(@"Secret.SelfDestruct.1m", nil);
    }
    
    if(ttl <= 60*60) {
        return NSLocalizedString(@"Secret.SelfDestruct.1h", nil);
    }
    
    if(ttl <= 60*60*24) {
        return NSLocalizedString(@"Secret.SelfDestruct.1d", nil);
    }
    
    if(ttl <= 60*60*24*7) {
        return NSLocalizedString(@"Secret.SelfDestruct.1w", nil);
    }
    
    return [NSString stringWithFormat:@"%d s",ttl];
}



+(NSMutableAttributedString *)conversationLastText:(TGMessage *)message conversation:(TL_conversation *)conversation {
    
    NSMutableAttributedString *messageText = [[NSMutableAttributedString alloc] init];
    [messageText setSelectionColor:NSColorFromRGB(0xcbe1f1) forColor:NSColorFromRGB(0x9b9b9b)];
    [messageText setSelectionColor:NSColorFromRGB(0xffffff) forColor:NSColorFromRGB(0x333333)];
    
    
    
    if(conversation.type == DialogTypeSecretChat) {
        EncryptedParams *params = conversation.encryptedChat.encryptedParams;
        
        if(params.state == EncryptedDiscarted) {
            
            [messageText appendString:NSLocalizedString(@"MessageAction.Secret.CancelledSecretChat",nil) withColor:NSColorFromRGB(0x9b9b9b)];
            
            
            [messageText endEditing];
            return messageText;
        } else if(params.state == EncryptedWaitOnline) {
            
            [messageText appendString:[NSString stringWithFormat:NSLocalizedString(@"MessageAction.Secret.WaitingToGetOnline",nil), conversation.encryptedChat.peerUser.first_name] withColor:NSColorFromRGB(0x9b9b9b)];
            
            [messageText endEditing];
            return messageText;
        } else if(params.state == EncryptedAllowed && conversation.top_message == -1) {
            
            NSString *actionFormat = [UsersManager currentUserId] == conversation.encryptedChat.admin_id ? NSLocalizedString(@"MessageAction.Secret.UserJoined",nil) : NSLocalizedString(@"MessageAction.Secret.CreatedSecretChat",nil);
            
            [messageText appendString:[NSString stringWithFormat:actionFormat,conversation.encryptedChat.peerUser.first_name] withColor:NSColorFromRGB(0x9b9b9b)];
            
            
            [messageText endEditing];
            return messageText;
        }
    }
    
    
    
    [messageText beginEditing];
    if(message) {
        
        NSString *msgText = @"";
        TGUser *userSecond = nil;
        TGUser *userLast;
        NSString *chatUserNameString;
        
        
        
        if(message.dialog.type == DialogTypeChat && !message.action ) {
            
            if(!message.n_out) {
                userLast = [[UsersManager sharedManager] find:message.from_id];
                chatUserNameString = [userLast ? userLast.dialogFullName : @"" stringByAppendingString:@": "];
            }
        }
        
        if(message.n_out)
            chatUserNameString = [NSString stringWithFormat:@"%@: ", NSLocalizedString(@"Profile.You", nil)];
        
        
        
        BOOL isAction = NO;
        
        if(message.action) {
            isAction = YES;
            if(!userLast)
                userLast = [[UsersManager sharedManager] find:message.from_id];
            // if(userLast == [UsersManager currentUser])
            //  chatUserNameString = NSLocalizedString(@"Profile.You", nil);
            //  else
            if(message.dialog.type != DialogTypeSecretChat)
                chatUserNameString = userLast ? userLast.dialogFullName : NSLocalizedString(@"MessageAction.Service.LeaveChat", nil);
            
            TGMessageAction *action = message.action;
            if([action isKindOfClass:[TL_messageActionChatEditTitle class]]) {
                msgText = NSLocalizedString(@"MessageAction.Service.ChangedGroupName", nil);
            } else if([action isKindOfClass:[TL_messageActionChatDeletePhoto class]]) {
                msgText = NSLocalizedString(@"MessageAction.Service.RemovedGroupPhoto", nil);
            } else if([action isKindOfClass:[TL_messageActionChatEditPhoto class]]) {
                msgText = NSLocalizedString(@"MessageAction.Service.ChangedGroupPhoto", nil);
            } else if([action isKindOfClass:[TL_messageActionChatAddUser class]]) {
                userSecond = [[UsersManager sharedManager] find:action.user_id];
                if(action.user_id == message.from_id) {
                    userSecond = nil;
                    msgText = NSLocalizedString(@"MessageAction.Service.JoinedGroup", nil);
                } else {
                    msgText = NSLocalizedString(@"MessageAction.Service.InvitedGroup", nil);
                }
            } else if([action isKindOfClass:[TL_messageActionChatCreate class]]) {
                msgText = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.Service.CreatedChat", nil),action.title];
            } else if([action isKindOfClass:[TL_messageActionChatDeleteUser class]]) {
                
                if(action.user_id != message.from_id) {
                    userSecond = [[UsersManager sharedManager] find:action.user_id];
                    
                    msgText = NSLocalizedString(@"MessageAction.Service.KickedGroup", nil);
                } else {
                    msgText = NSLocalizedString(@"MessageAction.Service.LeftGroup", nil);
                }
            } else if([action isKindOfClass:[TL_messageActionEncryptedChat class]]) {
                msgText = action.title;
            }
            
            msgText = [NSString stringWithFormat:@" %@", msgText];
        }
        
        if(chatUserNameString)
            [messageText appendString:chatUserNameString withColor:isAction ? NSColorFromRGB(0x9b9b9b) : NSColorFromRGB(0x333333)];
        
        
        if(!message.action) {
            if(message.media && ![message.media isKindOfClass:[TL_messageMediaEmpty class]]) {
                msgText = [MessagesUtils mediaMessage:message];
            } else {
                msgText = message.message ? message.message : @"";
                msgText = [msgText trim];
            }
            
            if(!msgText.length)
                msgText = @"";
        }
        
        msgText = [msgText stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        
        if(msgText) {
            [messageText appendString:msgText withColor:NSColorFromRGB(0x9b9b9b)];
        }
        
        if(userSecond) {
            [messageText appendString:[NSString stringWithFormat:@" %@", userSecond.dialogFullName] withColor:NSColorFromRGB(0x9b9b9b)];
        }
        
    } else {
        [messageText appendString:@"" withColor:LIGHT_GRAY];
    }
    
    [messageText setAlignment:NSLeftTextAlignment range:NSMakeRange(0, messageText.length)];
    
    
    
    [messageText endEditing];
    
    return messageText;
}

+ (NSAttributedString *) serviceAttributedMessage:(TGMessage *)message forAction:(TGMessageAction *)action {
    
    TGUser *user = [[UsersManager sharedManager] find:message.from_id];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    TGUser *user2;
    NSString *actionText;
    
    NSString *title;
    
    if([action isKindOfClass:[TL_messageActionChatEditTitle class]]) {
        
        actionText = NSLocalizedString(@"MessageAction.Service.ChangedGroupName",nil);
        title = action.title;
        
    } else if([action isKindOfClass:[TL_messageActionChatDeletePhoto class]]) {
        
        actionText = NSLocalizedString(@"MessageAction.Service.RemovedGroupPhoto",nil);;
        
    } else if([action isKindOfClass:[TL_messageActionChatEditPhoto class]]) {
        
        actionText = NSLocalizedString(@"MessageAction.Service.ChangedGroupPhoto",nil);
        
    } else if([action isKindOfClass:[TL_messageActionChatAddUser class]]) {
        
        if(action.user_id != message.from_id) {
            user2 = [[UsersManager sharedManager] find:action.user_id];
            actionText = NSLocalizedString(@"MessageAction.Service.InvitedGroup",nil);
        } else {
            actionText = NSLocalizedString(@"MessageAction.Service.JoinedGroup", nil);
        }
        
    } else if([action isKindOfClass:[TL_messageActionChatCreate class]]) {
        
        actionText = [NSString stringWithFormat:NSLocalizedString(@"MessageAction.Service.CreatedChat",nil), action.title];
        
    } else if([action isKindOfClass:[TL_messageActionChatDeleteUser class]]) {
        
        if(action.user_id != message.from_id) {
            user2  = [[UsersManager sharedManager] find:action.user_id];
            actionText = NSLocalizedString(@"MessageAction.Service.KickedGroup",nil);
        } else {
            actionText = NSLocalizedString(@"MessageAction.Service.LeftGroup",nil);
        }
    } else if([action isKindOfClass:[TL_messageActionEncryptedChat class]]) {
        actionText = action.title;
    }
    
    static float size = 11.5;
    
    NSRange start;
    //  if(user != [UsersManager currentUser]) {
    start = [attributedString appendString:[user fullName] withColor:LINK_COLOR];
    [attributedString setLink:[TMInAppLinks userProfile:user.n_id] forRange:start];
    [attributedString setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:size] forRange:start];
    //    } else {
    //        start = [attributedString appendString:NSLocalizedString(@"Profile.You", nil) withColor:NSColorFromRGB(0xaeaeae)];
    //        [attributedString setLink:[TMInAppLinks userProfile:user.n_id] forRange:start];
    //        [attributedString setFont:[NSFont fontWithName:@"HelveticaNeue-Bold" size:size] forRange:start];
    //    }
    
    
    start = [attributedString appendString:[NSString stringWithFormat:@" %@ ", actionText] withColor:NSColorFromRGB(0xaeaeae)];
    [attributedString setFont:[NSFont fontWithName:@"HelveticaNeue" size:size] forRange:start];
    
    if(user2) {
        start = [attributedString appendString:[user2 fullName] withColor:LINK_COLOR];
        [attributedString setLink:[TMInAppLinks userProfile:user2.n_id] forRange:start];
        [attributedString setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:size] forRange:start];
    }
    
    if(title) {
        start = [attributedString appendString:[NSString stringWithFormat:@"\"%@\"", title] withColor:NSColorFromRGB(0xaeaeae)];
        [attributedString setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:size] forRange:start];
    }
    
    //    [attributedString appendString:@"wqeqoeqwe wqkeqwoewkq keqwoei qoioiweiqwioeoqweiwqoi qoiweoiqwoiewqoieoiqweoiwqeoiwqoeiwqoieoiw oiqweoiqwoieqwoieoqwi"];
    
    return attributedString;
}

+ (NSImage *) dialogPhotoForUid:(int)uid {
    int avatar = abs(uid) % 8;
    return [NSImage imageNamed:[NSString stringWithFormat:@"DialogListAvatar%d", avatar + 1]];
}

+ (NSImage *) messagePhotoForUid:(int)uid {
    int avatar = abs(uid) % 8;
    return [NSImage imageNamed:[NSString stringWithFormat:@"ConversationAvatar%d", avatar + 1]];
}


+ (NSColor *) colorForUserId:(int)uid {
    //e76568 - e88f4e - 49ae5a - 3991c7 - 606ce5 - a663d0
    
    static NSMutableDictionary *cacheColorIds;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacheColorIds = [[NSMutableDictionary alloc] init];
    });
    
    
    int colorMask;
    
    if(cacheColorIds[@(uid)]) {
        colorMask = [cacheColorIds[@(uid)] intValue];
    } else {
        const int numColors = 8;
        
        if(uid != -1) {
            char buf[16];
            snprintf(buf, 16, "%d%d", uid, [UsersManager currentUserId]);
            unsigned char digest[CC_MD5_DIGEST_LENGTH];
            CC_MD5(buf, (unsigned) strlen(buf), digest);
            colorMask = ABS(digest[ABS(uid % 16)]) % numColors;
        } else {
            colorMask = -1;
        }
        
        cacheColorIds[@(uid)] = @(colorMask);
    }
    
    
    static const int colors[] = {0xe76568,0xe88f4e,0x49ae5a,0x3991c7,0x606ce5,0xa663d0};
    
    int color = colors[colorMask % (sizeof(colors) / sizeof(colors[0]))];
    
    return  NSColorFromRGB(color);
}

+ (NSString *) mediaMessage:(TGMessage *)message {
    if([message.media isKindOfClass:[TL_messageMediaPhoto class]]) {
        return NSLocalizedString(@"ChatMedia.Photo", nil);
    } else if([message.media isKindOfClass:[TL_messageMediaContact class]]) {
        return NSLocalizedString(@"ChatMedia.Contact", nil);
    } else if([message.media isKindOfClass:[TL_messageMediaVideo class]]) {
        return NSLocalizedString(@"ChatMedia.Video", nil);
    } else if([message.media isKindOfClass:[TL_messageMediaGeo class]]) {
        return NSLocalizedString(@"ChatMedia.Location", nil);
    } else if([message.media isKindOfClass:[TL_messageMediaAudio class]]) {
        return NSLocalizedString(@"ChatMedia.Audio", nil);
    } else if([message.media isKindOfClass:[TL_messageMediaDocument class]]) {
        return NSLocalizedString(@"ChatMedia.File", nil);
    } else {
        return NSLocalizedString(@"ChatMedia.Unsupported", nil);
    }
    
}






@end
