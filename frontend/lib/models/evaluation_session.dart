class EvaluationSession {
  const EvaluationSession({
    required this.id,
    required this.scenarioTitle,
    required this.date,
    required this.fluency,
    required this.avgScore,
    required this.icon,
    required this.colorHex,
  });

  final String id;
  final String scenarioTitle;
  final String date;
  final double fluency;
  final double avgScore;
  final String icon;
  final int colorHex;

  factory EvaluationSession.fromJson(Map<String, dynamic> json) {
    final dynamic scenarioField = json['scenario'];
    String? scenarioFromMap;
    if (scenarioField is Map<String, dynamic>) {
      scenarioFromMap = scenarioField['title'] as String?;
    }

    final String title = _readString(json, const <String>[
      'scenario_title',
      'title',
      'name',
    ], fallback: scenarioFromMap ?? 'Practice Session');

    return EvaluationSession(
      id: _readString(json, const <String>[
        'id',
        'attempt_id',
      ], fallback: 'unknown'),
      scenarioTitle: title,
      date: _readString(json, const <String>[
        'date',
        'created_at',
        'updated_at',
      ], fallback: 'N/A'),
      fluency: _readDouble(json, const <String>[
        'fluency',
        'fluency_score',
      ], fallback: 0),
      avgScore: _readDouble(json, const <String>[
        'avg_score',
        'overall_score',
        'score',
      ], fallback: 0),
      icon: _readString(json, const <String>['icon'], fallback: 'analytics'),
      colorHex: _readColor(json, fallback: 0xFF2962FF),
    );
  }
}

class ScoreDimension {
  const ScoreDimension({required this.label, required this.score});

  final String label;
  final double score;
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

int _readColor(Map<String, dynamic> json, {required int fallback}) {
  final dynamic colorValue =
      json['colorHex'] ?? json['color_hex'] ?? json['color'];
  if (colorValue is int) {
    return colorValue;
  }
  if (colorValue is String) {
    final String normalized = colorValue.replaceAll('#', '').trim();
    final int? parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) {
      if (normalized.length <= 6) {
        return 0xFF000000 | parsed;
      }
      return parsed;
    }
  }
  return fallback;
}
