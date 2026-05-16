// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_stream_chat_suppression.dart';

const _tracerName = 'dartastic_otel_libs_stream_chat';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class StreamChatResult {
  const StreamChatResult({
    this.apiKey,
    this.userId,
    this.channelId,
    this.channelType,
    this.messageId,
    this.messageType,
    this.parentMessageId,
    this.attachmentCount,
    this.mentionedUserCount,
    this.reactionType,
    this.connectionState,
    this.unreadChannels,
    this.unreadMessages,
    this.rateLimitRemaining,
    this.rateLimitLimit,
    this.errorCode,
    this.statusCode,
  });

  /// Stream Chat API key.
  final String? apiKey;

  final String? userId;

  /// `<type>:<id>` is the canonical channel cid; we split:
  final String? channelId;

  /// `messaging`, `team`, `livestream`, `commerce`, `gaming`.
  final String? channelType;

  final String? messageId;

  /// `regular`, `reply`, `system`, `ephemeral`, `error`, `deleted`.
  final String? messageType;

  /// Parent message id for thread replies.
  final String? parentMessageId;

  final int? attachmentCount;
  final int? mentionedUserCount;

  /// Reaction type on `sendReaction` (`like`, `love`, `haha`, ...).
  final String? reactionType;

  /// `connecting`, `connected`, `disconnected`, `disconnecting`,
  /// `wait_for_health_check`.
  final String? connectionState;

  final int? unreadChannels;
  final int? unreadMessages;

  final int? rateLimitRemaining;
  final int? rateLimitLimit;

  /// Stream error code (numeric, e.g. 4 — not allowed, 16 — invalid token,
  /// 17 — channel access denied, 60 — flood control).
  final int? errorCode;

  final int? statusCode;
}

class StreamChatCallResult<T> {
  const StreamChatCallResult({required this.value, this.result});
  final T value;
  final StreamChatResult? result;
}

/// Wraps a Stream Chat call in a CLIENT span. [operation] is one of
/// `connectUser`, `connectAnonymousUser`, `connectGuestUser`,
/// `disconnectUser`, `channel`, `watch`, `query`, `queryChannels`,
/// `queryUsers`, `queryMessageFlags`, `queryReactions`, `queryThreads`,
/// `sendMessage`, `updateMessage`, `deleteMessage`, `pinMessage`,
/// `unpinMessage`, `sendReaction`, `deleteReaction`, `sendFile`,
/// `sendImage`, `deleteFile`, `deleteImage`, `sendEvent`, `markRead`,
/// `markAllRead`, `addMembers`, `removeMembers`, `inviteMembers`,
/// `acceptInvite`, `rejectInvite`, `truncateChannel`, `freezeChannel`,
/// `unfreezeChannel`, `addDevice`, `removeDevice`, `getDevices`,
/// `muteUser`, `unmuteUser`, `flagMessage`, `unflagMessage`,
/// `flagUser`, `banUser`, `unbanUser`, `shadowBan`,
/// `translateMessage`, `getOG`, `enrichUrl`.
Future<T> tracedStreamChat<T>({
  required String operation,
  required Future<StreamChatCallResult<T>> Function() invoke,
}) async {
  if (streamChatInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'stream_chat',
    'rpc.method': operation,
    'stream_chat.operation': operation,
  };

  final span = _tracer().startSpan(
    'stream_chat $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.apiKey != null) {
        extras.add(OTel.attributeString('stream_chat.api_key', res.apiKey!));
      }
      if (res.userId != null) {
        extras.add(OTel.attributeString('stream_chat.user.id', res.userId!));
      }
      if (res.channelId != null) {
        extras.add(OTel.attributeString(
          'stream_chat.channel.id',
          res.channelId!,
        ));
      }
      if (res.channelType != null) {
        extras.add(OTel.attributeString(
          'stream_chat.channel.type',
          res.channelType!,
        ));
      }
      if (res.messageId != null) {
        extras.add(OTel.attributeString(
          'stream_chat.message.id',
          res.messageId!,
        ));
      }
      if (res.messageType != null) {
        extras.add(OTel.attributeString(
          'stream_chat.message.type',
          res.messageType!,
        ));
        if (res.messageType == 'error') {
          span.setStatus(SpanStatusCode.Error, 'Stream Chat message error');
        }
      }
      if (res.parentMessageId != null) {
        extras.add(OTel.attributeString(
          'stream_chat.message.parent_id',
          res.parentMessageId!,
        ));
      }
      if (res.attachmentCount != null) {
        extras.add(OTel.attributeInt(
          'stream_chat.message.attachment.count',
          res.attachmentCount!,
        ));
      }
      if (res.mentionedUserCount != null) {
        extras.add(OTel.attributeInt(
          'stream_chat.message.mentioned_user.count',
          res.mentionedUserCount!,
        ));
      }
      if (res.reactionType != null) {
        extras.add(OTel.attributeString(
          'stream_chat.reaction.type',
          res.reactionType!,
        ));
      }
      if (res.connectionState != null) {
        extras.add(OTel.attributeString(
          'stream_chat.connection.state',
          res.connectionState!,
        ));
      }
      if (res.unreadChannels != null) {
        extras.add(OTel.attributeInt(
          'stream_chat.unread.channels',
          res.unreadChannels!,
        ));
      }
      if (res.unreadMessages != null) {
        extras.add(OTel.attributeInt(
          'stream_chat.unread.messages',
          res.unreadMessages!,
        ));
      }
      if (res.rateLimitRemaining != null) {
        extras.add(OTel.attributeInt(
          'stream_chat.rate_limit.remaining',
          res.rateLimitRemaining!,
        ));
      }
      if (res.rateLimitLimit != null) {
        extras.add(OTel.attributeInt(
          'stream_chat.rate_limit.limit',
          res.rateLimitLimit!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeInt(
          'stream_chat.error.code',
          res.errorCode!,
        ));
        span.setStatus(
          SpanStatusCode.Error,
          'Stream Chat error ${res.errorCode}',
        );
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Stream Chat HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
