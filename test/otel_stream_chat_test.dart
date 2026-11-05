// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_stream_chat/otel_stream_chat.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_stream_chat-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('sendMessage records channel + attachments + rate limit', () async {
    await tracedStreamChat<String>(
      operation: 'sendMessage',
      invoke: () async => const StreamChatCallResult(
        value: 'ok',
        result: StreamChatResult(
          apiKey: 'pk_1',
          userId: 'u_1',
          channelId: 'general',
          channelType: 'messaging',
          messageId: 'm_1',
          messageType: 'regular',
          attachmentCount: 2,
          mentionedUserCount: 1,
          rateLimitRemaining: 90,
          rateLimitLimit: 100,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('stream_chat sendMessage')!);
    expect(a['stream_chat.channel.type'], 'messaging');
    expect(a['stream_chat.message.attachment.count'], 2);
    expect(a['stream_chat.rate_limit.remaining'], 90);
  });

  test('flood control error sets span error', () async {
    await tracedStreamChat<String>(
      operation: 'sendMessage',
      invoke: () async => const StreamChatCallResult(
        value: 'ok',
        result: StreamChatResult(errorCode: 60, statusCode: 429),
      ),
    );
    final s = spans.findSpanByName('stream_chat sendMessage')!;
    expect(s.status, SpanStatusCode.Error);
    expect(attrsOf(s)['stream_chat.error.code'], 60);
  });

  test('message type error sets span error', () async {
    await tracedStreamChat<String>(
      operation: 'sendMessage',
      invoke: () async => const StreamChatCallResult(
        value: 'ok',
        result: StreamChatResult(messageType: 'error'),
      ),
    );
    expect(
      spans.findSpanByName('stream_chat sendMessage')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutStreamChatInstrumentationAsync(() async {
      await tracedStreamChat<String>(
        operation: 'connectUser',
        invoke: () async => const StreamChatCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('stream_chat '), isEmpty);
  });
}
