import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:speaksense_app/app/env.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeEvent {
  const RealtimeEvent({
    required this.type,
    required this.receivedAt,
    this.attemptId,
    this.message,
  });

  final String type;
  final String? attemptId;
  final String? message;
  final DateTime receivedAt;

  bool get isEvaluationCompleted => type == 'evaluation.completed';

  factory RealtimeEvent.fromPayload(Map<String, dynamic> payload) {
    final String type = _readString(payload, const <String>[
      'type',
      'event',
      'name',
    ], fallback: 'unknown');
    final Map<String, dynamic>? eventPayload =
        payload['payload'] as Map<String, dynamic>?;

    return RealtimeEvent(
      type: type,
      attemptId: _readString(eventPayload ?? payload, const <String>[
        'attempt_id',
        'attemptId',
        'id',
      ], fallback: '').ifEmptyToNull(),
      message: _readString(eventPayload ?? payload, const <String>[
        'message',
        'text',
      ], fallback: '').ifEmptyToNull(),
      receivedAt: DateTime.now().toUtc(),
    );
  }

  static RealtimeEvent? tryParse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return RealtimeEvent.fromPayload(raw);
    }
    if (raw is! String) {
      return null;
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return RealtimeEvent.fromPayload(decoded);
  }
}

class WebSocketService {
  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _reconnectTimer;
  bool _isStarted = false;
  bool _isDisposed = false;
  int _reconnectAttempt = 0;

  Stream<RealtimeEvent> get events => _eventController.stream;

  void start() {
    if (_isDisposed || _isStarted) {
      return;
    }
    _isStarted = true;
    _connect();
  }

  void stop() {
    _isStarted = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    stop();
    _eventController.close();
  }

  void emitDebugEvaluationCompleted() {
    _eventController.add(
      RealtimeEvent(
        type: 'evaluation.completed',
        attemptId: 'debug-attempt',
        message: '模拟事件：评估已完成',
        receivedAt: DateTime.now().toUtc(),
      ),
    );
  }

  void _connect() {
    if (!_isStarted || _isDisposed) {
      return;
    }

    final Uri uri = Uri.parse(AppEnv.wsEventsUrl);
    try {
      _channel = WebSocketChannel.connect(uri);
      _channelSubscription = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      _reconnectAttempt = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    final RealtimeEvent? event = RealtimeEvent.tryParse(raw);
    if (event == null) {
      return;
    }
    _eventController.add(event);
  }

  void _scheduleReconnect() {
    if (!_isStarted || _isDisposed) {
      return;
    }
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _reconnectTimer?.cancel();

    _reconnectAttempt += 1;
    final int delaySeconds = min(pow(2, _reconnectAttempt).toInt(), 20);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _connect);
  }
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  required String fallback,
}) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

extension on String {
  String? ifEmptyToNull() {
    if (trim().isEmpty) {
      return null;
    }
    return this;
  }
}
