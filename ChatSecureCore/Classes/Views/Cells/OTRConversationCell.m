//
//  OTRConversationCell.m
//  Off the Record
//
//  Created by David Chiles on 3/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRConversationCell.h"

@import OTRAssets;
@import YapDatabase;

#import "ChatSecureCoreCompat-Swift.h"

#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRDatabaseManager.h"
#import "OTRMediaItem.h"
#import "OTRImageItem.h"
#import "OTRAudioItem.h"
#import "OTRVideoItem.h"

@interface OTRConversationCell ()

@property (nonatomic, strong) NSArray *verticalConstraints;
@property (nonatomic, strong) NSArray *accountHorizontalConstraints;

@end

@implementation OTRConversationCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.showAccountLabel = NO;
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont boldSystemFontOfSize:17];
        self.nameLabel.textColor = [GlobalTheme.shared labelColor];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.dateLabel.textColor = [GlobalTheme.shared secondaryLabelColor];
        self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.conversationLabel = [[UILabel alloc] init];
        self.conversationLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.conversationLabel.numberOfLines = 0;
        self.conversationLabel.font = [UIFont fontWithName:@"FontAwesome" size:15];
        self.conversationLabel.textColor = [GlobalTheme.shared secondaryLabelColor];
        self.conversationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.accountLabel = [[UILabel alloc] init];
        self.accountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addSubview:self.dateLabel];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.conversationLabel];
        
    }
    return self;
}

- (void) setShowAccountLabel:(BOOL)showAccountLabel
{
    _showAccountLabel = showAccountLabel;
    
    if (!self.showAccountLabel) {
        [self.accountLabel removeFromSuperview];
    }
    else {
        [self.contentView addSubview:self.accountLabel];
    }
}

- (void) setThread:(id <OTRThreadOwner>)thread
{
    [super setThread:thread];
    NSString * nameString = [thread threadName];

    self.nameLabel.text = nameString;

    __block OTRAccount *account = nil;
    __block id <OTRMessageProtocol> lastMessage = nil;
    __block NSUInteger unreadMessages = 0;
    __block OTRMediaItem *mediaItem = nil;
    
    /// this is so we can show who sent a group message
    __block OTRXMPPBuddy *groupBuddy = nil;
    
    [[OTRDatabaseManager sharedInstance].uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [transaction objectForKey:[thread threadAccountIdentifier] inCollection:[OTRAccount collection]];
        unreadMessages = [thread numberOfUnreadMessagesWithTransaction:transaction];
        lastMessage = [thread lastMessageWithTransaction:transaction];
        groupBuddy = [lastMessage buddyWithTransaction:transaction];
        if (lastMessage.messageMediaItemKey) {
            mediaItem = [OTRMediaItem fetchObjectWithUniqueID:lastMessage.messageMediaItemKey transaction:transaction];
        }
    }];
    
    self.accountLabel.text = account.username;
    
    //UIFont *currentFont = self.conversationLabel.font;
    //CGFloat fontSize = currentFont.pointSize;
    NSError *messageError = lastMessage.messageError;
    NSString *messageText = lastMessage.messageText;
    if (!messageText) {
        messageText = @"";
    }
    
    NSString *messageTextPrefix = @"";
    
    if (lastMessage.isMessageIncoming) {
        
        messageTextPrefix = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FAClockO]];
        
        if (unreadMessages > 1)
        {
            messageTextPrefix = [NSString stringWithFormat:@"(%lu) ", (unsigned long)unreadMessages];
        }
        
        if(lastMessage.isMessageRead)
        {
            messageTextPrefix = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FACheckCircle]];
        }
        
    } else {
        
        messageTextPrefix = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FAClockO]];
        
        if(lastMessage.isMessageSent)
        {
            messageTextPrefix = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FACheckCircleO]];
        }
        
        if(lastMessage.isMessageDelivered)
        {
            messageTextPrefix = [NSString stringWithFormat:@"%@ ",[NSString fa_stringForFontAwesomeIcon:FACheckCircle]];
        }
    }
    
    /*
    else
    }
    */
    
    if (messageError &&
        !messageError.isAutomaticDownloadError) {
        if (!messageText.length) {
            messageText = ERROR_STRING();
        }
        self.conversationLabel.text = [NSString stringWithFormat:@"%@", messageText];
    } else if (mediaItem) {
        self.conversationLabel.text = [messageTextPrefix stringByAppendingString:mediaItem.displayText];
    } else {
        self.conversationLabel.text = [messageTextPrefix stringByAppendingString:messageText];
    }
    /*
    if (unreadMessages > 0) {
        //unread message
        self.conversationLabel.textColor = [UIColor blackColor];
        self.dateLabel.textColor = [UIColor blackColor];
        //self.dateLabel.text = [NSString stringWithFormat:@"(%lu) %@", (unsigned long)unreadMessages, self.dateLabel.text];
    } else {
    
        self.conversationLabel.textColor = [UIColor grayColor];//colorWithWhite:.75 alpha:1.0];
        self.dateLabel.textColor = [UIColor grayColor];//colorWithWhite:.75 alpha:1.0];
    }
    */
    [self updateDateString:lastMessage.messageDate];
}



- (void) updateDateString:(NSDate *)date
{
    self.dateLabel.text = [self dateString:date];
}

- (NSString *) dateString:(NSDate *)messageDate
{
    if (!messageDate) {
        return @"";
    }
    NSTimeInterval timeInterval = fabs([messageDate timeIntervalSinceNow]);
    NSString * dateString = nil;
    /*
    if (timeInterval < 60){
        dateString = @"Только что";
    }
    else if (timeInterval < 60*60) {
        int minsInt = timeInterval/60;
        NSString * minString = @"мин";
        if (minsInt == 1) {
            minString = @"мин";
        }
        dateString = [NSString stringWithFormat:@"%d %@",minsInt,minString];
    }
    else */if (timeInterval < 60*60*24){
        // show time in format 11:00 PM
        dateString = [NSDateFormatter localizedStringFromDate:messageDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    }
    else if (timeInterval < 60*60*24*7) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEE" options:0 locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
        
    }
    else if (timeInterval < 60*60*25*365) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMM" options:0
                                                                   locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    }
    else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMYYYY" options:0
                                                                    locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    }
    
    return dateString;
}

- (void) updateConstraints
{
    NSDictionary *views = @{@"imageView": self.avatarImageView,
                            @"conversationLabel": self.conversationLabel,
                            @"dateLabel":self.dateLabel,
                            @"nameLabel":self.nameLabel,
                            //@"conversationLabel":self.conversationLabel,
                            @"accountLabel":self.accountLabel};
    
    NSDictionary *metrics = @{@"margin":[NSNumber numberWithFloat:OTRBuddyImageCellPadding]};
    if (!self.addedConstraints) {
        
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[nameLabel]->=0-[dateLabel]-margin-|"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[conversationLabel]-margin-|"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[dateLabel]" options:0 metrics:metrics
                                                                                   views:views]];
        
        
    }
    
    if([self.accountHorizontalConstraints count])
    {
        [self.contentView removeConstraints:self.accountHorizontalConstraints];
    }
    
    if([self.verticalConstraints count]) {
        [self.contentView removeConstraints:self.verticalConstraints];
    }
    
    if (self.showAccountLabel) {
        self.accountHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[accountLabel]|"
                                                                                    options:0
                                                                                    metrics:metrics
                                                                                      views:views];
        
        self.verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[nameLabel][conversationLabel][accountLabel]-margin-|"
                                                                           options:0
                                                                           metrics:metrics
                                                                             views:views];
        
    }
    else {
        self.accountHorizontalConstraints = @[];
        
        self.verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[nameLabel][conversationLabel(30)]-margin-|"
                                                                           options:0
                                                                           metrics:metrics
                                                                             views:views];
    }
    if([self.accountHorizontalConstraints count]) {
        [self.contentView addConstraints:self.accountHorizontalConstraints];
    }
    
    [self.contentView addConstraints:self.verticalConstraints];
    [super updateConstraints];
}

@end
