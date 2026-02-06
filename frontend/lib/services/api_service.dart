import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:speaksense_app/app/env.dart';

class ApiRequestException implements Exception {
  ApiRequestException({
    required this.message,
    this.code,
    this.type,
    this.statusCode,
    this.details,
    this.innerError,
  });

  final String message;
  final String? code;
  final String? type;
  final int? statusCode;
  final dynamic details;
  final Object? innerError;

  @override
  String toString() {
    final List<String> parts = <String>[message];
    if (code != null && code!.trim().isNotEmpty) {
      parts.add('(code: $code)');
    }
    if (statusCode != null) {
      parts.add('(status: $statusCode)');
    }
    if (innerError != null) {
      parts.add(': $innerError');
    }
    return parts.join(' ');
  }

  factory ApiRequestException.fromDioException(
    DioException error, {
    required String fallbackMessage,
  }) {
    final int? statusCode = error.response?.statusCode;
    final dynamic payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      final dynamic errorField = payload['error'];
      if (errorField is Map<String, dynamic>) {
        return ApiRequestException(
          message: _readString(errorField, const <String>[
            'message',
          ], fallback: fallbackMessage),
          code: _readNullableString(errorField, const <String>['code']),
          type: _readNullableString(errorField, const <String>['type']),
          statusCode: statusCode,
          details: errorField['details'],
          innerError: error,
        );
      }
    }

    return ApiRequestException(
      message: fallbackMessage,
      statusCode: statusCode,
      innerError: error,
    );
  }
}

class ApiService {
  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppEnv.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const <String, String>{'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchBoards() {
    return _fetchList(
      paths: const <String>['/v1/boards'],
      collectionKeys: const <String>['boards'],
    );
  }

  Future<List<Map<String, dynamic>>> fetchEvaluationSessions() {
    return _fetchList(
      paths: const <String>['/v1/attempts', '/v1/evaluations'],
      collectionKeys: const <String>['attempts', 'sessions', 'evaluations'],
    );
  }

  Future<Map<String, dynamic>> fetchEvaluationDetail(String sessionId) {
    return _fetchMap(
      paths: <String>[
        '/v1/attempts/$sessionId/evaluation',
        '/v1/evaluations/$sessionId',
        '/v1/attempts/$sessionId',
      ],
      objectKeys: const <String>['evaluation', 'attempt', 'result', 'data'],
    );
  }

  Future<List<Map<String, dynamic>>> fetchWordbook() {
    return _fetchList(
      paths: const <String>['/v1/wordbook', '/v1/vocab'],
      collectionKeys: const <String>['words', 'vocabulary'],
    );
  }

  Future<VoiceAnswerResponse> uploadVoiceAnswer({
    required Uint8List audioBytes,
    required String fileName,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    Object? lastError;
    for (final String path in const <String>[
      '/v1/answers/voice',
      '/v1/practice/answers/voice',
    ]) {
      try {
        final FormData formData = FormData.fromMap(<String, dynamic>{
          'audio': MultipartFile.fromBytes(audioBytes, filename: fileName),
        });
        final Response<dynamic> response = await _dio.post<dynamic>(
          path,
          data: formData,
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
          options: Options(
            headers: <String, String>{
              'Idempotency-Key':
                  'voice-${DateTime.now().millisecondsSinceEpoch}',
            },
            contentType: 'multipart/form-data',
          ),
        );
        return VoiceAnswerResponse.fromPayload(response.data);
      } catch (error) {
        if (error is DioException && CancelToken.isCancel(error)) {
          throw ApiRequestException(
            message: '上传已取消',
            code: 'UPLOAD_CANCELLED',
            innerError: error,
          );
        }
        if (error is DioException) {
          lastError = ApiRequestException.fromDioException(
            error,
            fallbackMessage: '语音上传失败',
          );
          continue;
        }
        lastError = error;
      }
    }

    if (lastError is ApiRequestException) {
      throw lastError;
    }
    throw ApiRequestException(
      message: 'Voice upload failed for /v1/answers/voice',
      innerError: lastError,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchList({
    required List<String> paths,
    List<String> collectionKeys = const <String>[],
  }) async {
    Object? lastError;
    for (final String path in paths) {
      try {
        final Response<dynamic> response = await _dio.get<dynamic>(path);
        return _extractMapList(response.data, collectionKeys);
      } catch (error) {
        lastError = error;
      }
    }
    throw ApiRequestException(
      message: 'API request failed for ${paths.join(', ')}',
      innerError: lastError,
    );
  }

  Future<Map<String, dynamic>> _fetchMap({
    required List<String> paths,
    List<String> objectKeys = const <String>[],
  }) async {
    Object? lastError;
    for (final String path in paths) {
      try {
        final Response<dynamic> response = await _dio.get<dynamic>(path);
        return _extractMap(response.data, objectKeys);
      } catch (error) {
        lastError = error;
      }
    }
    throw ApiRequestException(
      message: 'API request failed for ${paths.join(', ')}',
      innerError: lastError,
    );
  }

  List<Map<String, dynamic>> _extractMapList(
    dynamic payload,
    List<String> collectionKeys,
  ) {
    if (payload is List<dynamic>) {
      return payload.whereType<Map<String, dynamic>>().toList();
    }
    if (payload is! Map<String, dynamic>) {
      return const <Map<String, dynamic>>[];
    }

    final List<dynamic>? directData = payload['data'] as List<dynamic>?;
    if (directData != null) {
      return directData.whereType<Map<String, dynamic>>().toList();
    }

    final Map<String, dynamic>? wrappedData =
        payload['data'] as Map<String, dynamic>?;
    if (wrappedData != null) {
      final List<Map<String, dynamic>> nested = _extractFromKeys(
        wrappedData,
        collectionKeys,
      );
      if (nested.isNotEmpty) {
        return nested;
      }
    }

    final List<Map<String, dynamic>> rootItems = _extractFromKeys(
      payload,
      collectionKeys,
    );
    if (rootItems.isNotEmpty) {
      return rootItems;
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractMap(
    dynamic payload,
    List<String> objectKeys,
  ) {
    if (payload is Map<String, dynamic>) {
      final Map<String, dynamic>? data =
          payload['data'] as Map<String, dynamic>?;
      if (data != null) {
        return data;
      }
      final Map<String, dynamic>? nested = _extractObjectFromKeys(
        payload,
        objectKeys,
      );
      if (nested != null) {
        return nested;
      }
      return payload;
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractFromKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final List<String> candidates = <String>[
      ...keys,
      'items',
      'results',
      'list',
    ];
    for (final String key in candidates) {
      final dynamic value = map[key];
      if (value is List<dynamic>) {
        return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? _extractObjectFromKeys(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = payload[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return null;
  }
}

class VoiceAnswerResponse {
  const VoiceAnswerResponse({required this.transcript, required this.raw});

  final String transcript;
  final Map<String, dynamic> raw;

  factory VoiceAnswerResponse.fromPayload(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return const VoiceAnswerResponse(
        transcript: '',
        raw: <String, dynamic>{},
      );
    }

    final Map<String, dynamic>? data = payload['data'] as Map<String, dynamic>?;
    final Map<String, dynamic> scope = data ?? payload;
    final String transcript = _readTranscript(scope);

    return VoiceAnswerResponse(transcript: transcript, raw: payload);
  }
}

String _readTranscript(Map<String, dynamic> scope) {
  for (final String key in const <String>[
    'transcript',
    'preview_text',
    'text',
    'asr_text',
  ]) {
    final dynamic value = scope[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

String _readString(
  Map<String, dynamic> map,
  List<String> keys, {
  required String fallback,
}) {
  for (final String key in keys) {
    final dynamic value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

String? _readNullableString(Map<String, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    final dynamic value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}
