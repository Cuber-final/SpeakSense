import 'package:speaksense_app/data/mock_data.dart';
import 'package:speaksense_app/models/evaluation_session.dart';
import 'package:speaksense_app/models/scenario.dart';
import 'package:speaksense_app/models/vocabulary_word.dart';
import 'package:speaksense_app/services/api_service.dart';

class RepositoryPayload<T> {
  const RepositoryPayload({
    required this.data,
    required this.fromMock,
    this.notice,
  });

  final T data;
  final bool fromMock;
  final String? notice;
}

class ContentRepository {
  ContentRepository({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;

  Future<RepositoryPayload<List<Scenario>>> loadScenarios({
    required bool useMockApi,
  }) async {
    if (useMockApi) {
      return const RepositoryPayload<List<Scenario>>(
        data: kScenarios,
        fromMock: true,
      );
    }

    try {
      final List<Map<String, dynamic>> response = await _apiService
          .fetchBoards();
      final List<Scenario> boards = response.map(Scenario.fromJson).toList();
      if (boards.isEmpty) {
        return const RepositoryPayload<List<Scenario>>(
          data: kScenarios,
          fromMock: true,
          notice: 'API 返回为空，已自动回退到 Mock 数据。',
        );
      }
      return RepositoryPayload<List<Scenario>>(data: boards, fromMock: false);
    } catch (_) {
      return const RepositoryPayload<List<Scenario>>(
        data: kScenarios,
        fromMock: true,
        notice: 'API 不可用，已自动回退到 Mock 数据。',
      );
    }
  }

  Future<RepositoryPayload<List<EvaluationSession>>> loadEvaluationSessions({
    required bool useMockApi,
  }) async {
    if (useMockApi) {
      return const RepositoryPayload<List<EvaluationSession>>(
        data: kEvaluationSessions,
        fromMock: true,
      );
    }

    try {
      final List<Map<String, dynamic>> response = await _apiService
          .fetchEvaluationSessions();
      final List<EvaluationSession> sessions = response
          .map(EvaluationSession.fromJson)
          .toList();
      if (sessions.isEmpty) {
        return const RepositoryPayload<List<EvaluationSession>>(
          data: kEvaluationSessions,
          fromMock: true,
          notice: '评估 API 返回为空，已自动回退到 Mock 数据。',
        );
      }
      return RepositoryPayload<List<EvaluationSession>>(
        data: sessions,
        fromMock: false,
      );
    } catch (_) {
      return const RepositoryPayload<List<EvaluationSession>>(
        data: kEvaluationSessions,
        fromMock: true,
        notice: '评估 API 不可用，已自动回退到 Mock 数据。',
      );
    }
  }

  Future<RepositoryPayload<List<VocabularyWord>>> loadVocabulary({
    required bool useMockApi,
  }) async {
    if (useMockApi) {
      return const RepositoryPayload<List<VocabularyWord>>(
        data: kVocabularyWords,
        fromMock: true,
      );
    }

    try {
      final List<Map<String, dynamic>> response = await _apiService
          .fetchWordbook();
      final List<VocabularyWord> words = response
          .map(VocabularyWord.fromJson)
          .toList();
      if (words.isEmpty) {
        return const RepositoryPayload<List<VocabularyWord>>(
          data: kVocabularyWords,
          fromMock: true,
          notice: '词本 API 返回为空，已自动回退到 Mock 数据。',
        );
      }
      return RepositoryPayload<List<VocabularyWord>>(
        data: words,
        fromMock: false,
      );
    } catch (_) {
      return const RepositoryPayload<List<VocabularyWord>>(
        data: kVocabularyWords,
        fromMock: true,
        notice: '词本 API 不可用，已自动回退到 Mock 数据。',
      );
    }
  }
}
