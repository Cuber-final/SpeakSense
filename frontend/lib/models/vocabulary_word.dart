enum WordStatus { mastered, reviewing, fresh }

class VocabularyWord {
  const VocabularyWord({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.level,
    required this.translation,
    required this.source,
    required this.status,
  });

  final String id;
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String level;
  final String translation;
  final String source;
  final WordStatus status;

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: _readString(json, const <String>[
        'id',
        'word_id',
      ], fallback: 'unknown'),
      word: _readString(json, const <String>[
        'word',
        'text',
      ], fallback: 'Unknown'),
      phonetic: _readString(json, const <String>[
        'phonetic',
        'pronunciation',
      ], fallback: '/-/'),
      partOfSpeech: _readString(json, const <String>[
        'part_of_speech',
        'partOfSpeech',
        'pos',
      ], fallback: 'n.'),
      level: _readString(json, const <String>['level'], fallback: 'B1'),
      translation: _readString(json, const <String>[
        'translation',
        'meaning',
      ], fallback: '-'),
      source: _readString(json, const <String>[
        'source',
        'provenance',
      ], fallback: 'Unknown Source'),
      status: _parseStatus(
        _readString(json, const <String>[
          'status',
          'review_status',
        ], fallback: 'fresh'),
      ),
    );
  }
}

extension WordStatusX on WordStatus {
  String get label {
    return switch (this) {
      WordStatus.mastered => 'Mastered',
      WordStatus.reviewing => 'Reviewing',
      WordStatus.fresh => 'New',
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

WordStatus _parseStatus(String raw) {
  final String value = raw.toLowerCase();
  return switch (value) {
    'mastered' => WordStatus.mastered,
    'reviewing' => WordStatus.reviewing,
    'fresh' || 'new' => WordStatus.fresh,
    _ => WordStatus.fresh,
  };
}
