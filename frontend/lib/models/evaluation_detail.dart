import 'package:speaksense_app/models/evaluation_session.dart';

class EvaluationDetail {
  const EvaluationDetail({
    required this.id,
    required this.scenarioTitle,
    required this.overallScore,
    required this.level,
    required this.summary,
    required this.dimensions,
    required this.metrics,
    required this.questions,
  });

  final String id;
  final String scenarioTitle;
  final double overallScore;
  final String level;
  final String summary;
  final List<ScoreDimension> dimensions;
  final List<EvaluationMetric> metrics;
  final List<EvaluationQuestion> questions;

  factory EvaluationDetail.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> evaluation = _readMap(
          json,
          const <String>['evaluation', 'result', 'data'],
        ) ??
        json;
    final Map<String, dynamic> attempt =
        _readMap(json, const <String>['attempt', 'session']) ?? json;

    final String scenarioTitle = _readString(
      evaluation,
      const <String>['scenario_title', 'scenarioTitle', 'title', 'name'],
      fallback: _readNestedScenarioTitle(attempt) ??
          _readNestedScenarioTitle(evaluation) ??
          'Practice Session',
    );

    final double overallScore = _readDouble(
      evaluation,
      const <String>['overall_score', 'score', 'avg_score', 'overallScore'],
      fallback: _readDouble(
        attempt,
        const <String>['overall_score', 'score', 'avg_score', 'overallScore'],
        fallback: 0,
      ),
    );

    final String level = _readString(
      evaluation,
      const <String>['level', 'grade', 'rating'],
      fallback: 'Intermediate',
    );

    final String summary = _readString(
      evaluation,
      const <String>['summary', 'comment', 'feedback', 'note'],
      fallback:
          'Great progress overall. Keep practicing to improve consistency.',
    );

    final List<ScoreDimension> dimensions =
        _parseDimensions(evaluation['dimensions']) ??
            _parseDimensions(evaluation['scores']) ??
            _parseDimensions(evaluation['radar']) ??
            _parseDimensions(evaluation['metrics']) ??
            const <ScoreDimension>[];

    final List<EvaluationMetric> metrics =
        _parseMetrics(evaluation['metrics']) ??
            _parseMetrics(evaluation['key_metrics']) ??
            _parseMetrics(evaluation['stats']) ??
            _metricsFromFields(evaluation, attempt);

    final List<EvaluationQuestion> questions =
        _parseQuestions(evaluation['questions']) ??
            _parseQuestions(evaluation['items']) ??
            _parseQuestions(evaluation['breakdown']) ??
            const <EvaluationQuestion>[];

    return EvaluationDetail(
      id: _readString(
        evaluation,
        const <String>['id', 'attempt_id', 'session_id'],
        fallback: _readString(
          attempt,
          const <String>['id', 'attempt_id', 'session_id'],
          fallback: 'unknown',
        ),
      ),
      scenarioTitle: scenarioTitle,
      overallScore: overallScore,
      level: level,
      summary: summary,
      dimensions: dimensions,
      metrics: metrics,
      questions: questions,
    );
  }
}

class EvaluationMetric {
  const EvaluationMetric({
    required this.label,
    required this.value,
    this.key,
  });

  final String label;
  final String value;
  final String? key;
}

class EvaluationQuestion {
  const EvaluationQuestion({
    required this.prompt,
    required this.answer,
    required this.feedback,
    required this.suggestedAnswer,
    required this.dimensions,
    this.audioUrl,
  });

  final String prompt;
  final String answer;
  final String feedback;
  final String suggestedAnswer;
  final List<ScoreDimension> dimensions;
  final String? audioUrl;
}

String? _readNestedScenarioTitle(Map<String, dynamic> json) {
  final dynamic scenario = json['scenario'];
  if (scenario is Map<String, dynamic>) {
    final String? title = scenario['title'] as String?;
    if (title != null && title.trim().isNotEmpty) {
      return title;
    }
  }
  return null;
}

List<ScoreDimension>? _parseDimensions(dynamic payload) {
  if (payload is List<dynamic>) {
    final List<ScoreDimension> items = payload
        .whereType<Map<String, dynamic>>()
        .map(_dimensionFromMap)
        .whereType<ScoreDimension>()
        .toList();
    if (items.isNotEmpty) {
      return items;
    }
  }
  if (payload is Map<String, dynamic>) {
    final List<ScoreDimension> items = payload.entries
        .map((MapEntry<String, dynamic> entry) {
          if (entry.value is num) {
            return ScoreDimension(
              label: _titleCase(entry.key),
              score: (entry.value as num).toDouble(),
            );
          }
          if (entry.value is String) {
            final double? parsed = double.tryParse(entry.value as String);
            if (parsed != null) {
              return ScoreDimension(
                label: _titleCase(entry.key),
                score: parsed,
              );
            }
          }
          return null;
        })
        .whereType<ScoreDimension>()
        .toList();
    if (items.isNotEmpty) {
      return items;
    }
  }
  return null;
}

ScoreDimension? _dimensionFromMap(Map<String, dynamic> map) {
  final String label = _readString(
    map,
    const <String>['label', 'name', 'dimension', 'title'],
    fallback: '',
  );
  if (label.trim().isEmpty) {
    return null;
  }
  final double score = _readDouble(
    map,
    const <String>['score', 'value', 'rating'],
    fallback: 0,
  );
  return ScoreDimension(label: label, score: score);
}

List<EvaluationMetric>? _parseMetrics(dynamic payload) {
  if (payload is List<dynamic>) {
    final List<EvaluationMetric> items = payload
        .whereType<Map<String, dynamic>>()
        .map(_metricFromMap)
        .whereType<EvaluationMetric>()
        .toList();
    if (items.isNotEmpty) {
      return items;
    }
  }
  return null;
}

EvaluationMetric? _metricFromMap(Map<String, dynamic> map) {
  final String label = _readString(
    map,
    const <String>['label', 'title', 'name'],
    fallback: '',
  );
  if (label.trim().isEmpty) {
    return null;
  }
  final String value = _readString(
    map,
    const <String>['value', 'text', 'display'],
    fallback: '',
  );
  final String? key = _readNullableString(
    map,
    const <String>['key', 'type', 'id'],
  );
  return EvaluationMetric(label: label, value: value, key: key);
}

List<EvaluationMetric> _metricsFromFields(
  Map<String, dynamic> evaluation,
  Map<String, dynamic> attempt,
) {
  final String duration = _readString(
    evaluation,
    const <String>['duration', 'duration_text'],
    fallback: _readString(
      attempt,
      const <String>['duration', 'duration_text'],
      fallback: '14m 32s',
    ),
  );
  final String pace = _readString(
    evaluation,
    const <String>['pace', 'pace_text'],
    fallback: _readString(
      attempt,
      const <String>['pace', 'pace_text'],
      fallback: '115 wpm',
    ),
  );
  final String vocab = _readString(
    evaluation,
    const <String>['vocabulary', 'vocab_level', 'vocabulary_level'],
    fallback: _readString(
      attempt,
      const <String>['vocabulary', 'vocab_level', 'vocabulary_level'],
      fallback: 'B2 Level',
    ),
  );
  return <EvaluationMetric>[
    EvaluationMetric(label: 'Duration', value: duration, key: 'duration'),
    EvaluationMetric(label: 'Pace', value: pace, key: 'pace'),
    EvaluationMetric(label: 'Vocabulary', value: vocab, key: 'vocabulary'),
  ];
}

List<EvaluationQuestion>? _parseQuestions(dynamic payload) {
  if (payload is List<dynamic>) {
    final List<EvaluationQuestion> items = payload
        .whereType<Map<String, dynamic>>()
        .map(_questionFromMap)
        .whereType<EvaluationQuestion>()
        .toList();
    if (items.isNotEmpty) {
      return items;
    }
  }
  return null;
}

EvaluationQuestion? _questionFromMap(Map<String, dynamic> map) {
  final String prompt = _readString(
    map,
    const <String>['question', 'prompt', 'title'],
    fallback: '',
  );
  if (prompt.trim().isEmpty) {
    return null;
  }
  final String answer = _readString(
    map,
    const <String>['answer', 'user_answer', 'response'],
    fallback: '',
  );
  final String feedback = _readString(
    map,
    const <String>['feedback', 'comment', 'note'],
    fallback: '',
  );
  final String suggested = _readString(
    map,
    const <String>['suggested_answer', 'suggested', 'ideal_answer'],
    fallback: '',
  );
  final List<ScoreDimension> dimensions =
      _parseDimensions(map['dimensions']) ?? const <ScoreDimension>[];
  final String? audioUrl = _readNullableString(
    map,
    const <String>['audio_url', 'audio', 'audioUrl'],
  );

  return EvaluationQuestion(
    prompt: prompt,
    answer: answer,
    feedback: feedback,
    suggestedAnswer: suggested,
    dimensions: dimensions,
    audioUrl: audioUrl,
  );
}

String _titleCase(String input) {
  if (input.isEmpty) {
    return input;
  }
  return input
      .split(RegExp(r'[_\\s]+'))
      .map((String word) {
        if (word.isEmpty) {
          return word;
        }
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

Map<String, dynamic>? _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
  }
  return null;
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

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

double _readDouble(
  Map<String, dynamic> json,
  List<String> keys, {
  required double fallback,
}) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final double? parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
}
