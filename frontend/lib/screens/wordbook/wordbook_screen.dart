import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speaksense_app/models/vocabulary_word.dart';
import 'package:speaksense_app/services/content_repository.dart';
import 'package:speaksense_app/widgets/data_source_banner.dart';

class WordbookScreen extends StatefulWidget {
  const WordbookScreen({required this.useMockApi, super.key});

  final bool useMockApi;

  @override
  State<WordbookScreen> createState() => _WordbookScreenState();
}

class _WordbookScreenState extends State<WordbookScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VocabularyWord> _words = const <VocabularyWord>[];
  String? _notice;
  bool _fromMock = true;
  bool _isLoading = true;
  WordStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void didUpdateWidget(covariant WordbookScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useMockApi != widget.useMockApi) {
      _loadWords();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
    });

    final ContentRepository repository = context.read<ContentRepository>();
    final RepositoryPayload<List<VocabularyWord>> payload = await repository
        .loadVocabulary(useMockApi: widget.useMockApi);

    if (!mounted) {
      return;
    }
    setState(() {
      _words = payload.data;
      _fromMock = payload.fromMock;
      _notice = payload.notice;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String query = _searchController.text.toLowerCase();
    final List<VocabularyWord> words = _words.where((VocabularyWord word) {
      final bool statusMatch =
          _statusFilter == null || word.status == _statusFilter;
      final bool queryMatch =
          word.word.toLowerCase().contains(query) ||
          word.translation.toLowerCase().contains(query);
      return statusMatch && queryMatch;
    }).toList();

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.book_rounded),
              const SizedBox(width: 8),
              Text(
                'Wordbook',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton(onPressed: _loadWords, child: const Text('Refresh')),
            ],
          ),
          const SizedBox(height: 12),
          DataSourceBanner(fromMock: _fromMock, notice: _notice),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search saved words...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilterChip(
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
                label: const Text('All Levels'),
              ),
              for (final WordStatus status in WordStatus.values)
                FilterChip(
                  selected: _statusFilter == status,
                  onSelected: (_) => setState(() => _statusFilter = status),
                  label: Text(status.label),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (words.isEmpty)
            const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No saved words yet.'),
              ),
            )
          else
            for (final VocabularyWord word in words) _WordTile(word: word),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Showing ${words.length} of 128 words',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word});

  final VocabularyWord word;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool mastered = word.status == WordStatus.mastered;
    final Color tone = mastered ? Colors.green : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: tone.withValues(alpha: 0.1),
            child: Icon(
              mastered ? Icons.check_circle_rounded : Icons.menu_book_rounded,
              color: tone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      word.word,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ],
                ),
                Text(
                  '${word.phonetic} • ${word.partOfSpeech} • ${word.level}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(word.translation),
                Text(
                  word.source,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              Text(
                word.status.label,
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Checkbox(value: mastered, onChanged: (_) {}),
            ],
          ),
        ],
      ),
    );
  }
}
