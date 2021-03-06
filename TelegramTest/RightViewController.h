//
//  RightViewController.h
//  TelegramTest
//
//  Created by Dmitry Kondratyev on 10/29/13.
//  Copyright (c) 2013 keepcoder. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MessagesViewController.h"
#import "UserInfoViewController.h"
#import "ChatInfoViewController.h"
#import "TMCollectionPageController.h"
#import "HistoryFilter.h"
#import "BroadcastInfoViewController.h"
#import "ComposeAction.h"
#import "ComposePickerViewController.h"
#import "ComposeChatCreateViewController.h"
#import "ComposeBroadcastListViewController.h"
#import "EncryptedKeyViewController.h"
@interface RightViewController : TMViewController

@property (nonatomic, strong) MessagesViewController *messagesViewController;
@property (nonatomic, strong) UserInfoViewController *userInfoViewController;
@property (nonatomic, strong) ChatInfoViewController *chatInfoViewController;
@property (nonatomic, strong) BroadcastInfoViewController *broadcastInfoViewController;
@property (nonatomic, strong) TMCollectionPageController *collectionViewController;
@property (nonatomic, strong) ComposePickerViewController *composePickerViewController;
@property (nonatomic, strong) ComposeChatCreateViewController *composeChatCreateViewController;
@property (nonatomic, strong) ComposeBroadcastListViewController *composeBroadcastListViewController;
@property (nonatomic, strong) EncryptedKeyViewController *encryptedKeyViewController;
- (void)modalViewSendAction:(id)object;
- (BOOL)isModalViewActive;
- (BOOL)isActiveDialog;
- (void)navigationGoBack;
- (void)hideModalView:(BOOL)isHide animation:(BOOL)animated;

- (void)showShareContactModalView:(TGUser *)user;
- (void)showForwardMessagesModalView:(TL_conversation *)dialog messagesCount:(NSUInteger)messagesCount;

- (void)showByDialog:(TL_conversation *)dialog sender:(id)sender;

- (BOOL)showByDialog:(TL_conversation *)dialog withJump:(int)messageId historyFilter:(Class)filter sender:(id)sender;

- (void)showComposeWithAction:(ComposeAction *)composeAction filter:(NSArray *)filter;

- (void)showComposeWithAction:(ComposeAction *)composeAction;
- (void)showComposeCreateChat:(ComposeAction *)composeAction;
- (void)showComposeBroadcastList:(ComposeAction *)composeAction;
- (void)showUserInfoPage:(TGUser *)user conversation:(TL_conversation *)conversation;
- (void)showUserInfoPage:(TGUser *)user;
- (void)showCollectionPage:(TL_conversation *)conversation;
- (void)showChatInfoPage:(TGChat *)chat;
- (void)showBroadcastInfoPage:(TL_broadcast *)broadcast;
- (void)showNotSelectedDialog;

-(void)showEncryptedKeyWindow:(TL_encryptedChat *)chat;

@end
