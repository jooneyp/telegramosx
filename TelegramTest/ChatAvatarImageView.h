//
//  ChatAvatarImageView.h
//  Messenger for Telegram
//
//  Created by Dmitry Kondratyev on 3/26/14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "TMAvatarImageView.h"
#import "TL_broadcast.h"
@class ChatInfoViewController;

@interface ChatAvatarImageView : TMAvatarImageView

typedef enum {
    ChatAvatarSourceUser,
    ChatAvatarSourceGroup,
    ChatAvatarSourceBroadcast
} ChatAvatarSourceType;


@property (nonatomic,assign) ChatAvatarSourceType sourceType;

@property (nonatomic,strong) TGUser *user;
@property (nonatomic,strong) TGChat *chat;

@property (nonatomic, strong) ChatInfoViewController *controller;
- (void)rebuild;
- (void)showUpdateChatPhotoBox;
@end
