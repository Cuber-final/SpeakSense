enum ScenarioLevel { a1, a2, b1, b2, c1, c2 }

enum ScenarioCategory { business, travel, dailyLife, academic, social }

class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.category,
    required this.questionCount,
    required this.icon,
    required this.colorHex,
  });

  final String id;
  final String title;
  final String description;
  final ScenarioLevel level;
  final ScenarioCategory category;
  final int questionCount;
  final String icon;
  final int colorHex;

  bool get isLocked => questionCount == 0;

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: _readString(json, const <String>[
        'id',
        'board_id',
      ], fallback: 'unknown'),
      title: _readString(json, const <String>[
        'title',
        'name',
      ], fallback: 'Untitled Scenario'),
      description: _readString(json, const <String>[
        'description',
        'summary',
      ], fallback: 'No description'),
      level: _parseLevel(
        _readString(json, const <String>[
          'level',
          'cefr_level',
        ], fallback: 'b1'),
      ),
      category: _parseCategory(
        _readString(json, const <String>[
          'category',
          'topic',
        ], fallback: 'daily_life'),
      ),
      questionCount: _readInt(json, const <String>[
        'question_count',
        'questions_count',
        'questionCount',
      ], fallback: 0),
      icon: _readString(json, const <String>['icon'], fallback: 'forum'),
      colorHex: _readColor(json, fallback: 0xFF2962FF),
    );
  }
}

extension ScenarioLevelX on ScenarioLevel {
  String get label {
    return switch (this) {
      ScenarioLevel.a1 => 'A1',
      ScenarioLevel.a2 => 'A2',
      ScenarioLevel.b1 => 'B1',
      ScenarioLevel.b2 => 'B2',
      ScenarioLevel.c1 => 'C1',
      ScenarioLevel.c2 => 'C2',
    };
  }
}

extension ScenarioCategoryX on ScenarioCategory {
  String get label {
    return switch (this) {
      ScenarioCategory.business => 'Business',
      ScenarioCategory.travel => 'Travel',
      ScenarioCategory.dailyLife => 'Daily Life',
      ScenarioCategory.academic => 'Academic',
      ScenarioCategory.social => 'Social',
    };
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

int _readInt(
  Map<String, dynamic> json,
  List<String> keys, {
  required int fallback,
}) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final int? parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
}

ScenarioLevel _parseLevel(String raw) {
  final String value = raw.toLowerCase();
  return switch (value) {
    'a1' => ScenarioLevel.a1,
    'a2' => ScenarioLevel.a2,
    'b1' => ScenarioLevel.b1,
    'b2' => ScenarioLevel.b2,
    'c1' => ScenarioLevel.c1,
    'c2' => ScenarioLevel.c2,
    _ => ScenarioLevel.b1,
  };
}

ScenarioCategory _parseCategory(String raw) {
  final String value = raw.toLowerCase().replaceAll(' ', '_');
  return switch (value) {
    'business' => ScenarioCategory.business,
    'travel' => ScenarioCategory.travel,
    'daily_life' || 'dailylife' => ScenarioCategory.dailyLife,
    'academic' => ScenarioCategory.academic,
    'social' => ScenarioCategory.social,
    _ => ScenarioCategory.dailyLife,
  };
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
