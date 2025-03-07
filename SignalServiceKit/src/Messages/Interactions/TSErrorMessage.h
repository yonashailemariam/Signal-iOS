//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

#import <SignalServiceKit/OWSReadTracking.h>
#import <SignalServiceKit/TSMessage.h>

NS_ASSUME_NONNULL_BEGIN

@class SSKProtoEnvelope;
@class SignalServiceAddress;
@class TSErrorMessageBuilder;

typedef NS_CLOSED_ENUM(int32_t, TSErrorMessageType) {
    TSErrorMessageNoSession,
    // DEPRECATED: We no longer create TSErrorMessageWrongTrustedIdentityKey, but
    // persisted legacy messages could exist indefinitely.
    TSErrorMessageWrongTrustedIdentityKey,
    TSErrorMessageInvalidKeyException,
    // unused
    TSErrorMessageMissingKeyId,
    TSErrorMessageInvalidMessage,
    // unused
    TSErrorMessageDuplicateMessage,
    TSErrorMessageInvalidVersion,
    TSErrorMessageNonBlockingIdentityChange,
    TSErrorMessageUnknownContactBlockOffer,
    TSErrorMessageGroupCreationFailed,
    TSErrorMessageSessionRefresh,
    TSErrorMessageDecryptionFailure,
};

extern NSUInteger TSErrorMessageSchemaVersion;

@interface ThreadlessErrorMessage : NSObject <OWSPreviewText>

+ (ThreadlessErrorMessage *)corruptedMessageInUnknownThread;

@end

#pragma mark -

@interface TSErrorMessage : TSMessage <OWSReadTracking>

- (instancetype)initMessageWithBuilder:(TSMessageBuilder *)messageBuilder NS_UNAVAILABLE;

- (instancetype)initWithGrdbId:(int64_t)grdbId
                        uniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                   attachmentIds:(NSArray<NSString *> *)attachmentIds
                            body:(nullable NSString *)body
                      bodyRanges:(nullable MessageBodyRanges *)bodyRanges
                    contactShare:(nullable OWSContact *)contactShare
                 expireStartedAt:(uint64_t)expireStartedAt
                       expiresAt:(uint64_t)expiresAt
                expiresInSeconds:(unsigned int)expiresInSeconds
               isGroupStoryReply:(BOOL)isGroupStoryReply
              isViewOnceComplete:(BOOL)isViewOnceComplete
               isViewOnceMessage:(BOOL)isViewOnceMessage
                     linkPreview:(nullable OWSLinkPreview *)linkPreview
                  messageSticker:(nullable MessageSticker *)messageSticker
                   quotedMessage:(nullable TSQuotedMessage *)quotedMessage
    storedShouldStartExpireTimer:(BOOL)storedShouldStartExpireTimer
           storyAuthorUuidString:(nullable NSString *)storyAuthorUuidString
              storyReactionEmoji:(nullable NSString *)storyReactionEmoji
                  storyTimestamp:(nullable NSNumber *)storyTimestamp
              wasRemotelyDeleted:(BOOL)wasRemotelyDeleted NS_UNAVAILABLE;

- (instancetype)initErrorMessageWithBuilder:(TSErrorMessageBuilder *)errorMessageBuilder NS_DESIGNATED_INITIALIZER
    NS_SWIFT_NAME(init(errorMessageWithBuilder:));

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                   attachmentIds:(NSArray<NSString *> *)attachmentIds
                            body:(nullable NSString *)body
                      bodyRanges:(nullable MessageBodyRanges *)bodyRanges
                    contactShare:(nullable OWSContact *)contactShare
                 expireStartedAt:(uint64_t)expireStartedAt
                       expiresAt:(uint64_t)expiresAt
                expiresInSeconds:(unsigned int)expiresInSeconds
               isGroupStoryReply:(BOOL)isGroupStoryReply
              isViewOnceComplete:(BOOL)isViewOnceComplete
               isViewOnceMessage:(BOOL)isViewOnceMessage
                     linkPreview:(nullable OWSLinkPreview *)linkPreview
                  messageSticker:(nullable MessageSticker *)messageSticker
                   quotedMessage:(nullable TSQuotedMessage *)quotedMessage
    storedShouldStartExpireTimer:(BOOL)storedShouldStartExpireTimer
           storyAuthorUuidString:(nullable NSString *)storyAuthorUuidString
              storyReactionEmoji:(nullable NSString *)storyReactionEmoji
                  storyTimestamp:(nullable NSNumber *)storyTimestamp
              wasRemotelyDeleted:(BOOL)wasRemotelyDeleted
                       errorType:(TSErrorMessageType)errorType
                            read:(BOOL)read
                recipientAddress:(nullable SignalServiceAddress *)recipientAddress
                          sender:(nullable SignalServiceAddress *)sender
             wasIdentityVerified:(BOOL)wasIdentityVerified
NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(grdbId:uniqueId:receivedAtTimestamp:sortId:timestamp:uniqueThreadId:attachmentIds:body:bodyRanges:contactShare:expireStartedAt:expiresAt:expiresInSeconds:isGroupStoryReply:isViewOnceComplete:isViewOnceMessage:linkPreview:messageSticker:quotedMessage:storedShouldStartExpireTimer:storyAuthorUuidString:storyReactionEmoji:storyTimestamp:wasRemotelyDeleted:errorType:read:recipientAddress:sender:wasIdentityVerified:));

// clang-format on

// --- CODE GENERATION MARKER

+ (instancetype)corruptedMessageWithEnvelope:(SSKProtoEnvelope *)envelope
                             withTransaction:(SDSAnyWriteTransaction *)transaction;

+ (instancetype)invalidVersionWithEnvelope:(SSKProtoEnvelope *)envelope
                           withTransaction:(SDSAnyWriteTransaction *)transaction;

+ (instancetype)invalidKeyExceptionWithEnvelope:(SSKProtoEnvelope *)envelope
                                withTransaction:(SDSAnyWriteTransaction *)transaction;

+ (instancetype)missingSessionWithEnvelope:(SSKProtoEnvelope *)envelope
                           withTransaction:(SDSAnyWriteTransaction *)transaction;

+ (instancetype)sessionRefreshWithEnvelope:(SSKProtoEnvelope *)envelope
                           withTransaction:(SDSAnyWriteTransaction *)transaction;

+ (instancetype)nonblockingIdentityChangeInThread:(TSThread *)thread
                                          address:(SignalServiceAddress *)address
                              wasIdentityVerified:(BOOL)wasIdentityVerified;

+ (instancetype)failedDecryptionForEnvelope:(SSKProtoEnvelope *)envelope
                           untrustedGroupId:(nullable NSData *)untrustedGroupId
                            withTransaction:(SDSAnyWriteTransaction *)transaction;

+ (instancetype)failedDecryptionForSender:(nullable SignalServiceAddress *)sender
                                   thread:(TSThread *)thread
                                timestamp:(uint64_t)timestamp
                              transaction:(SDSAnyWriteTransaction *)transaction;

@property (nonatomic, readonly) TSErrorMessageType errorType;
@property (nullable, nonatomic, readonly) SignalServiceAddress *sender;
@property (nullable, nonatomic, readonly) SignalServiceAddress *recipientAddress;

// This property only applies if errorType == .nonBlockingIdentityChange.
@property (nonatomic, readonly) BOOL wasIdentityVerified;

@end

NS_ASSUME_NONNULL_END
