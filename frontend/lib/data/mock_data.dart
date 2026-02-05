import 'package:speaksense_app/models/evaluation_session.dart';
import 'package:speaksense_app/models/scenario.dart';
import 'package:speaksense_app/models/vocabulary_word.dart';

const List<Scenario> kScenarios = <Scenario>[
  Scenario(
    id: '1',
    title: 'Coffee Shop Ordering',
    description:
        'Master the essential dialogue for ordering food and drinks in a busy cafe environment.',
    level: ScenarioLevel.a2,
    category: ScenarioCategory.dailyLife,
    questionCount: 10,
    icon: 'local_cafe',
    colorHex: 0xFF3B82F6,
  ),
  Scenario(
    id: '2',
    title: 'Job Interview Prep',
    description:
        'Practice professional self-introductions and answering complex behavioral questions.',
    level: ScenarioLevel.c1,
    category: ScenarioCategory.business,
    questionCount: 15,
    icon: 'work',
    colorHex: 0xFF8B5CF6,
  ),
  Scenario(
    id: '3',
    title: 'Airport Check-in',
    description:
        'Learn how to navigate ticketing, baggage handling, and security questions with ease.',
    level: ScenarioLevel.b1,
    category: ScenarioCategory.travel,
    questionCount: 8,
    icon: 'flight_takeoff',
    colorHex: 0xFFF59E0B,
  ),
  Scenario(
    id: '4',
    title: 'Daily Standup',
    description:
        'Participate effectively in agile team meetings and report your progress.',
    level: ScenarioLevel.b2,
    category: ScenarioCategory.business,
    questionCount: 12,
    icon: 'groups',
    colorHex: 0xFF10B981,
  ),
  Scenario(
    id: '5',
    title: 'Ordering at a Restaurant',
    description:
        'Learn basic polite phrases for requesting a table, ordering, and asking for the bill.',
    level: ScenarioLevel.a1,
    category: ScenarioCategory.dailyLife,
    questionCount: 6,
    icon: 'restaurant',
    colorHex: 0xFFF43F5E,
  ),
  Scenario(
    id: '6',
    title: "Doctor's Appointment",
    description:
        'Coming soon! Practice describing symptoms and understanding medical advice.',
    level: ScenarioLevel.b1,
    category: ScenarioCategory.dailyLife,
    questionCount: 0,
    icon: 'lock',
    colorHex: 0xFF64748B,
  ),
];

const List<EvaluationSession> kEvaluationSessions = <EvaluationSession>[
  EvaluationSession(
    id: '1',
    scenarioTitle: 'Coffee Shop Ordering',
    date: 'Oct 24, 2023 • 14:30 PM',
    fluency: 4.0,
    avgScore: 3.5,
    icon: 'local_cafe',
    colorHex: 0xFF3B82F6,
  ),
  EvaluationSession(
    id: '2',
    scenarioTitle: 'Job Interview Prep',
    date: 'Oct 22, 2023 • 09:15 AM',
    fluency: 4.5,
    avgScore: 4.2,
    icon: 'work',
    colorHex: 0xFF8B5CF6,
  ),
  EvaluationSession(
    id: '3',
    scenarioTitle: 'Airport Check-in',
    date: 'Oct 19, 2023 • 11:45 AM',
    fluency: 2.8,
    avgScore: 3.0,
    icon: 'flight_takeoff',
    colorHex: 0xFFF59E0B,
  ),
  EvaluationSession(
    id: '4',
    scenarioTitle: 'Restaurant Reservation',
    date: 'Oct 15, 2023 • 19:20 PM',
    fluency: 4.8,
    avgScore: 4.6,
    icon: 'restaurant',
    colorHex: 0xFF10B981,
  ),
];

const List<ScoreDimension> kScoreDimensions = <ScoreDimension>[
  ScoreDimension(label: 'Naturalness', score: 4.5),
  ScoreDimension(label: 'Richness', score: 4.2),
  ScoreDimension(label: 'Grammar', score: 3.8),
  ScoreDimension(label: 'Relevance', score: 4.0),
];

const List<VocabularyWord> kVocabularyWords = <VocabularyWord>[
  VocabularyWord(
    id: '1',
    word: 'Latte',
    phonetic: '/ˈlɑːteɪ/',
    partOfSpeech: 'n.',
    level: 'A2',
    translation: '拿铁',
    source: 'Coffee Shop Q1',
    status: WordStatus.mastered,
  ),
  VocabularyWord(
    id: '2',
    word: 'Paradigm',
    phonetic: '/ˈpærədaɪm/',
    partOfSpeech: 'n.',
    level: 'C1',
    translation: '范式',
    source: 'Business Debate',
    status: WordStatus.reviewing,
  ),
  VocabularyWord(
    id: '3',
    word: 'Resilience',
    phonetic: '/rɪˈzɪliəns/',
    partOfSpeech: 'n.',
    level: 'B2',
    translation: '韧性',
    source: 'Mental Health AI',
    status: WordStatus.reviewing,
  ),
  VocabularyWord(
    id: '4',
    word: 'Eloquent',
    phonetic: '/ˈeləkwənt/',
    partOfSpeech: 'adj.',
    level: 'C1',
    translation: '雄辩的',
    source: 'Public Speaking Session',
    status: WordStatus.mastered,
  ),
];
