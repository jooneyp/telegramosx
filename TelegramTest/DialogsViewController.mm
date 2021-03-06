//
//  DialogsViewController.m
//  TelegramTest
//
//  Created by Dmitry Kondratyev on 10/29/13.
//  Copyright (c) 2013 keepcoder. All rights reserved.
//

#import "DialogsViewController.h"
#import "Telegram.h"
#import "DialogsManager.h"
#import "TGPeer+Extensions.h"
#import "FakeDialog.h"
#import "Telegram.h"
#import "DialogTableObject.h"
#import "ImageUtils.h"
#import "TMElements.h"
#import "DialogTableItem.h"
#import "DialogTableItemView.h"
#include "map"

#import "SearchSeparatorItem.h"
#import "SearchSeparatorTableCell.h"
#import "SearchItem.h"
#import "SearchTableCell.h"

#import "ImageCache.h"
#import "DialogsHistoryController.h"

#import "DialogTableView.h"
#import "SearchViewController.h"
#import "TMTaskRequest.h"
#import "SelfDestructionController.h"

@interface DialogsViewController ()<TMSearchTextFieldDelegate>
@property (nonatomic, strong) DialogsHistoryController *historyController;
@property (nonatomic, strong) DialogTableView *tableView;
@property (nonatomic, strong) TL_conversation *selectedConversation;
@end

@implementation DialogsViewController

- (void)loadView {
    [super loadView];
    
    int topOffset = 50;
    
    self.view.wantsLayer = YES;
    
    //self.firstItem = [[DialogFirstItem alloc] init];
    
   // self.dialogFirstView = [[DialogTableFirstView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.view.bounds), 25)];
    
    self.historyController = [DialogsHistoryController sharedController];
    
    self.searchViewController.type = SearchTypeDialogs | SearchTypeMessages | SearchTypeContacts;
   
    NSRect tableRect = NSMakeRect(0, 0, NSWidth(self.view.frame), NSHeight(self.view.frame) - topOffset);
    
    self.tableView = [[DialogTableView alloc] initWithFrame:tableRect];
    self.tableView.tm_delegate = self;

    [self.view addSubview:self.tableView.containerView];
    
    self.mainView = self.tableView.containerView;

    
    self.tableView.defaultAnimation = NSTableViewAnimationEffectFade;
    
    [Notification addObserver:self selector:@selector(notificationLogout:) name:LOGOUT_EVENT];

    [Notification addObserver:self selector:@selector(notificationDialogsReload:) name:DIALOGS_NEED_FULL_RESORT];
    [Notification addObserver:self selector:@selector(notificationDialogToTop:) name:DIALOG_TO_TOP];
    [Notification addObserver:self selector:@selector(notificationDialogRemove:) name:DIALOG_DELETE];
    [Notification addObserver:self selector:@selector(notificationDialogChangePosition:) name:DIALOG_MOVE_POSITION];
    [Notification addObserver:self selector:@selector(notificationDialogSelectionChanged:) name:@"ChangeDialogSelection"];
    [self addScrollEvent];
    
    
    [[Storage manager] users:^(NSArray *result) {
        
        [[UsersManager sharedManager] addFromDB:result];
    
        [[BroadcastManager sharedManager] loadBroadcastList:^{
        
            [[Storage manager] loadChats:^(NSArray *chats) {
                [[ChatsManager sharedManager] add:chats];
            
                [self initConversations];
            
                [[BlockedUsersManager sharedManager] remoteLoad];
            
            }];
        }];
        
    }];
    
    [[Storage manager] unreadCount:^(int count) {
        [[MessagesManager sharedManager] setUnread_count:count];
    }];
    
}


-(void)initConversations {
    
    [[DialogsHistoryController sharedController] next:0 limit:20 callback:^(NSArray *result) {
        
        [[MTNetwork instance] startNetwork];
        
        if(result.count != 0) {
            
            [TMTaskRequest executeAll];
            
            [Notification perform:DIALOGS_NEED_FULL_RESORT data:@{KEY_DIALOGS:result}];
            [Notification perform:APP_RUN object:nil];
            
            [SelfDestructionController initialize];
            [TMTypingManager sharedManager];
            
        
            [[NewContactsManager sharedManager] fullReload];
            [[FullChatManager sharedManager] loadStored];
           
            
            
        } else if([DialogsHistoryController sharedController].state != DialogsHistoryStateEnd) {
            [self initConversations];
        }
        
    } usersCallback:nil];
}

- (void)addScrollEvent {
    id clipView = [[self.tableView enclosingScrollView] contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollViewDocumentOffsetChangingNotificationHandler:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:clipView];
}

- (void)removeScrollEvent {
    id clipView = [[self.tableView enclosingScrollView] contentView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:clipView];
}


-(void)notificationLogout:(NSNotification *)notification {
    [self.historyController drop];
    [self.tableView removeAllItems:YES];
}

- (void) scrollViewDocumentOffsetChangingNotificationHandler:(NSNotification *)aNotification {
    if(self.historyController.isLoading || self.historyController.state == DialogsHistoryStateEnd || ![self.tableView.scrollView isNeedUpdateBottom])
        return;
    
    static int limit = 30;
    [self loadhistory:limit];
}

-(void)loadhistory:(int)limit  {
    
    int offset = (int) self.tableView.count;
    
    if(self.historyController.state == DialogsHistoryStateNeedRemote) {
         NSArray *filtred = [self.tableView.list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.dialog.peer.class != %@ AND self.dialog.peer.class != %@",[TL_peerSecret class], [TL_peerBroadcast class]]];
        
        offset = (int) filtred.count;
    }
     
    [self.historyController next:offset limit:limit callback:^(NSArray *result) {
        
        [self insertAll:result];
        
        if(result.count < limit/3 && self.historyController.state != DialogsHistoryStateEnd) {
            [self loadhistory:limit];
        }
        
    } usersCallback:^(NSArray *) {
        
    }];
}

-(void)insertAll:(NSArray *)all {
    NSMutableArray *dialogs = [[NSMutableArray alloc] init];
    for(TL_conversation *dialog in all) {
        if(!dialog.isAddToList)
            continue;
        
        DialogTableItem *item = [[DialogTableItem alloc] initWithDialogItem:dialog];
        [dialogs addObject:item];
    }
    
    NSTableViewAnimationOptions animation = self.tableView.defaultAnimation;
    
    self.tableView.defaultAnimation = NSTableViewAnimationEffectNone;
    
    [self.tableView insert:dialogs startIndex:self.tableView.list.count tableRedraw:YES];
    
    self.tableView.defaultAnimation = animation;
    
    
    if([(DialogTableItem *)self.tableView.selectedItem dialog] != self.selectedConversation) {
        NSUInteger hash = [DialogTableItem hash:self.selectedConversation];
        if([self.tableView itemByHash:hash]) {
            [self.tableView cancelSelection];
            [self.tableView setSelectedByHash:hash];
        }
       
    }
}
- (void)dealloc {
    [Notification removeObserver:self];
    [self removeScrollEvent];
}

- (void) setHidden:(BOOL)isHidden {
    [super setHidden:isHidden];
    
    if(isHidden) {
        [self.tableView setHidden:YES];
    } else {
        [self.tableView setHidden:NO];
    }
}

//Notifications
- (void)notificationDialogSelectionChanged:(NSNotification *)notify {
    if([notify.userInfo objectForKey:@"sender"] != self) {
        TL_conversation *conversation = [notify.userInfo objectForKey:KEY_DIALOG];
        
        [self.tableView cancelSelection];

        if(![conversation isKindOfClass:NSNull.class]) {
            self.selectedConversation = conversation;
            NSUInteger hash = [DialogTableItem hash:self.selectedConversation];
            [self.tableView setSelectedByHash:hash];
        }
    }
}

- (void)notificationContactsReload:(NSNotification *)notify {
    
    DLog(@"notification reload");
}

- (void) notificationDialogRemove:(NSNotification *)notify {
    TL_conversation *dialog = [notify.userInfo objectForKey:KEY_DIALOG];
  //  DialogTableItem *dialogItem = [[DialogTableItem alloc] initWithDialogItem:dialog];
     id object = [self.tableView itemByHash:[DialogTableItem hash:dialog]];
    [self.tableView removeItem:object];
}

- (void) notificationDialogsReload:(NSNotification *)notify {
    
    DLog(@"reload dialogs");
    
    [self.tableView removeAllItems:NO];
    NSArray *current = [[DialogsManager sharedManager] all];
    
    NSMutableArray *dialogs = [[NSMutableArray alloc] init];
    
    [ASQueue dispatchOnStageQueue:^{
        
        for(TL_conversation *dialog in current) {
            if(!dialog.isAddToList)
                continue;
            
            DialogTableItem *item = [[DialogTableItem alloc] initWithDialogItem:dialog];
            
            [dialogs addObject:item];
        }
    } synchronous:YES];
    
    
   // [self.tableView insert:self.firstItem atIndex:0 tableRedraw:NO];
    
    [self.tableView insert:dialogs startIndex:0 tableRedraw:NO];
    [self.tableView reloadData];
}

- (void)notificationDialogToTop:(NSNotification *)notify {
    TL_conversation *dialog = [notify.userInfo objectForKey:KEY_DIALOG];
    [self move:0 dialog:dialog];
}

- (void)notificationDialogChangePosition:(NSNotification *)notify {
    TL_conversation *dialog = [notify.userInfo objectForKey:KEY_DIALOG];
    int position = [[notify.userInfo objectForKey:KEY_POSITION] intValue];
    [self move:position dialog:dialog];
}

-(void)move:(int)position dialog:(TL_conversation *)dialog {
    
    
    if(position == 0 && dialog.top_message > TGMINFAKEID) {
        [self.tableView scrollToBeginningOfDocument:self];
    } 
    
    if(position != 0 && position >= self.tableView.count)
        position = (int) self.tableView.count-1;
    
    
    DialogTableItem *object = (DialogTableItem *) [self.tableView itemByHash:[DialogTableItem hash:dialog]];
    if(object) {
        [self.tableView moveItemFrom:[self.tableView positionOfItem:object] to:position tableRedraw:YES];
    } else {
        object = [[DialogTableItem alloc] initWithDialogItem:dialog];
        [self.tableView insert:object atIndex:position tableRedraw:YES];
        if(dialog == [Telegram rightViewController].messagesViewController.dialog)
            [self.tableView setSelectedByHash:object.hash];
    }
    
}

- (CGFloat) rowHeight:(NSUInteger)row item:(TMRowItem *)item {
    if([item isKindOfClass:[SearchSeparatorItem class]]) {
        return 25.0f;
    } else if([item isKindOfClass:[DialogTableItem class]]) {
        return DIALOG_CELL_HEIGHT;
    }
    return DIALOG_CELL_HEIGHT;
}

- (BOOL) isGroupRow:(NSUInteger)row item:(TMRowItem *) item {
    return NO;
}

- (NSView *)viewForRow:(NSUInteger)row item:(TMRowItem *)item {
    
    if([item isKindOfClass:[SearchSeparatorItem class]]) {
        return [self.tableView cacheViewForClass:[SearchSeparatorTableCell class] identifier:@"separatorItem"];
    } else if([item isKindOfClass:[DialogTableItem class]]) {
        DialogTableItemView *view = (DialogTableItemView *)[self.tableView cacheViewForClass:[DialogTableItemView class] identifier:@"dialogItem" withSize:NSMakeSize(200, DIALOG_CELL_HEIGHT)];
        view.tableView = self.tableView;
        return view;
    } else if([item isKindOfClass:[SearchItem class]]) {
        return [self.tableView cacheViewForClass:[SearchTableCell class] identifier:@"searchItem"];
    }
    
    return nil;
}

- (BOOL) selectionWillChange:(NSInteger)row item:(TMRowItem *) item {
    DialogTableItem *dialog = (DialogTableItem *) item;
    if([[Telegram rightViewController] isModalViewActive]) {
        [[Telegram rightViewController] modalViewSendAction:dialog.dialog];
        return NO;
    }
    return YES;
}

- (void) selectionDidChange:(NSInteger)row item:(TMRowItem *) item {
    DialogTableItem *dialog = (DialogTableItem *) item;
    [[Telegram sharedInstance] showMessagesFromDialog:dialog.dialog sender:self];
}

+ (void)showPopupMenuForDialog:(TL_conversation *)dialog withEvent:(NSEvent *)theEvent forView:(NSView *)view {
    NSMenu *menu = [[NSMenu alloc] init];
    
    __block TGUser *user = dialog.type == DialogTypeSecretChat ? dialog.encryptedChat.peerUser : dialog.user;
    __block TGChat *chat = dialog.chat;
    
    NSMenuItem *openConversationMenuItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Conversation.OpenConversation", nil) withBlock:^(id sender) {
        [[Telegram rightViewController] showByDialog:dialog sender:self];
    }];
    if([Telegram rightViewController].messagesViewController.dialog == dialog)
        openConversationMenuItem.target = nil;
    
    [menu addItem:openConversationMenuItem];
    
    
    if(dialog.type != DialogTypeSecretChat && dialog.type != DialogTypeBroadcast) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *clearHistory = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Profile.ClearHistory", nil) withBlock:^(id sender) {
            [[Telegram rightViewController].messagesViewController clearHistory:dialog];
        }];
        [menu addItem:clearHistory];
        
        BOOL isMuted = dialog.isMute;
        
        NSMenuItem *muteMenuItem = [NSMenuItem menuItemWithTitle:isMuted ? NSLocalizedString(@"Conversation.Unmute", nil) : NSLocalizedString(@"Conversation.Mute", nil) withBlock:^(id sender) {
            [dialog muteOrUnmute:nil];
        }];
        if(dialog.type == DialogTypeSecretChat)
            muteMenuItem.target = nil;
        [menu addItem:muteMenuItem];
    }
    
    
    
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    if(dialog.type != DialogTypeChat && dialog.type != DialogTypeBroadcast) {
        NSMenuItem *showUserProfile = [NSMenuItem menuItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Conversation.ShowProfile", nil), user.dialogFullName] withBlock:^(id sender) {
            [[Telegram rightViewController] showUserInfoPage:user conversation:user.dialog];
        }];
        [menu addItem:showUserProfile];
        
        
        
        if(user.type == TGUserTypeRequest) {
            [menu addItem:[NSMenuItem separatorItem]];
            __block BOOL isBlocked = [[BlockedUsersManager sharedManager] isBlocked:user.n_id];
            NSMenuItem *blockUser = [NSMenuItem menuItemWithTitle:[NSString stringWithFormat:isBlocked ? NSLocalizedString(@"User.UnlockUser", nil) : NSLocalizedString(@"User.BlockUser", nil), user.dialogFullName] withBlock:^(id sender) {
                
                if(isBlocked) {
                    [[BlockedUsersManager sharedManager] unblock:user.n_id completeHandler:nil];
                } else {
                    [[BlockedUsersManager sharedManager] block:user.n_id completeHandler:nil];
                }
            }];
            [menu addItem:blockUser];
            
            NSMenuItem *addToContacts = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"User.AddToContacts", nil) withBlock:^(id sender) {
                [[NewContactsManager sharedManager] importContact:[TL_inputPhoneContact createWithClient_id:0 phone:user.phone first_name:user.first_name last_name:user.last_name] callback:^(BOOL isAdd, TL_importedContact *contact, TGUser *user) {
                    
                }];
            }];
            [menu addItem:addToContacts];
        }
        
        if(dialog.type == DialogTypeSecretChat) {
            [menu addItem:[NSMenuItem separatorItem]];
            NSMenuItem *deleteMenuItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Conversation.DeleteSecretChat", nil) withBlock:^(id sender) {
                [[Telegram rightViewController].messagesViewController deleteDialog:dialog];
            }];
            [menu addItem:deleteMenuItem];
        }
        
    } else {
        
         NSMenuItem *showСhatProfile;
        
        if(dialog.type == DialogTypeChat) {
            showСhatProfile = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Conversation.ShowGroupInfo", nil) withBlock:^(id sender) {
                [[Telegram rightViewController] showChatInfoPage:chat];
            }];

        } else {
            showСhatProfile = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Conversation.ShowBroadcastInfo", nil) withBlock:^(id sender) {
                [[Telegram rightViewController] showBroadcastInfoPage:dialog.broadcast];
            }];

        }
        
       
        if(chat.type != TGChatTypeNormal || chat.left)
            showСhatProfile.target = nil;
        
        [menu addItem:showСhatProfile];
        
        
        if(dialog.type == DialogTypeChat) {
            
            [menu addItem:[NSMenuItem separatorItem]];
            
            NSMenuItem *deleteAndExitItem = [NSMenuItem menuItemWithTitle:chat.type == TGChatTypeNormal ? NSLocalizedString(@"Profile.DeleteAndExit", nil) : NSLocalizedString(@"Profile.DeleteConversation", nil)  withBlock:^(id sender) {
                [[Telegram rightViewController].messagesViewController deleteDialog:dialog];
            }];
            [menu addItem:deleteAndExitItem];
            
            NSMenuItem *leaveFromGroupItem = [NSMenuItem menuItemWithTitle:!dialog.chat.left ? NSLocalizedString(@"Conversation.Actions.LeaveGroup", nil) : NSLocalizedString(@"Conversation.Actions.ReturnToGroup", nil) withBlock:^(id sender) {
                [[Telegram rightViewController].messagesViewController leaveOrReturn:dialog];
            }];
            if(chat.type != TGChatTypeNormal)
                leaveFromGroupItem.target = nil;
            
            [menu addItem:leaveFromGroupItem];
        }
    }
    
    [NSMenu popUpContextMenu:menu withEvent:theEvent forView:view];
}



- (BOOL)isSelectable:(NSInteger)row item:(TMRowItem *)item {
    return [item isKindOfClass:[SearchSeparatorItem class]] ? NO : YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [TMTableView setCurrent:self.tableView];
}

@end
