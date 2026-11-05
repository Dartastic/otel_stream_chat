// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_stream_chat/otel_stream_chat.dart';

/// Traces Stream Chat calls with OpenTelemetry.
///
/// `otel_stream_chat` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Stream Chat call in
/// [tracedStreamChat]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'stream-chat-example');

  // Wraps a Stream Chat call in a CLIENT span.
  final streamChatId = await tracedStreamChat<String>(
    operation: 'create',
    invoke: () async {
      // Make the Stream Chat call here, then report what it returned.
      const id = 'stream_chat_8f3a2c';
      return const StreamChatCallResult(
          value: id,
          result: StreamChatResult(
              apiKey: 'orders/2026/inv-1042.pdf',
              userId: 'user_8f3a2c',
              channelId: '<type>:<id>',
              channelType: 'messaging',
              messageId: 'message_8f3a2c',
              messageType: 'regular',
              parentMessageId: 'parentmessage_8f3a2c',
              attachmentCount: 3,
              mentionedUserCount: 3,
              reactionType: 'sendReaction',
              connectionState: 'connecting',
              unreadChannels: 1,
              unreadMessages: 1,
              rateLimitRemaining: 25,
              rateLimitLimit: 25,
              errorCode: 1,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedStreamChat create returned $streamChatId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutStreamChatInstrumentationAsync.
  await runWithoutStreamChatInstrumentationAsync(
    () => tracedStreamChat<String>(
      operation: 'create',
      invoke: () async {
        const id = 'stream_chat_8f3a2c';
        return const StreamChatCallResult(
            value: id,
            result: StreamChatResult(
                apiKey: 'orders/2026/inv-1042.pdf',
                userId: 'user_8f3a2c',
                channelId: '<type>:<id>',
                channelType: 'messaging',
                messageId: 'message_8f3a2c',
                messageType: 'regular',
                parentMessageId: 'parentmessage_8f3a2c',
                attachmentCount: 3,
                mentionedUserCount: 3,
                reactionType: 'sendReaction',
                connectionState: 'connecting',
                unreadChannels: 1,
                unreadMessages: 1,
                rateLimitRemaining: 25,
                rateLimitLimit: 25,
                errorCode: 1,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
