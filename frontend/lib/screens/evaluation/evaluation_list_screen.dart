import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speaksense_app/models/evaluation_session.dart';
import 'package:speaksense_app/services/content_repository.dart';
import 'package:speaksense_app/utils/material_icon_mapper.dart';
import 'package:speaksense_app/widgets/data_source_banner.dart';

class EvaluationListScreen extends StatefulWidget {
  const EvaluationListScreen({
    required this.useMockApi,
    required this.onOpenDetail,
    super.key,
  });

  final bool useMockApi;
  final ValueChanged<String> onOpenDetail;

  @override
  State<EvaluationListScreen> createState() => _EvaluationListScreenState();
}

class _EvaluationListScreenState extends State<EvaluationListScreen> {
  List<EvaluationSession> _sessions = const <EvaluationSession>[];
  String? _notice;
  bool _fromMock = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void didUpdateWidget(covariant EvaluationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useMockApi != widget.useMockApi) {
      _loadSessions();
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    final ContentRepository repository = context.read<ContentRepository>();
    final RepositoryPayload<List<EvaluationSession>> payload = await repository
        .loadEvaluationSessions(useMockApi: widget.useMockApi);

    if (!mounted) {
      return;
    }
    setState(() {
      _sessions = payload.data;
      _fromMock = payload.fromMock;
      _notice = payload.notice;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Evaluation Hub',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track your spoken English progress across scenarios.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _loadSessions,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DataSourceBanner(fromMock: _fromMock, notice: _notice),
          const SizedBox(height: 14),
          const _StatsRow(),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Evaluation History',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Last 30 Days'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No evaluation sessions available.'),
                    )
                  else
                    for (final EvaluationSession session in _sessions)
                      _SessionTile(
                        session: session,
                        onTap: () => widget.onOpenDetail(session.id),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tip: Practice at least 15 minutes daily for faster fluency gains.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 900;
        final List<Widget> items = <Widget>[
          _StatCard(title: 'Overall Performance', value: '76%', footer: '+5%'),
          _StatCard(title: 'Total Sessions', value: '24', footer: '+2 wk'),
          _StatCard(
            title: 'Global Avg. Score',
            value: '3.8 / 5.0',
            footer: '+0.2',
          ),
        ];

        if (compact) {
          return Column(
            children: items
                .map(
                  (Widget item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: item,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          children: items
              .map(
                (Widget item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: item,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.footer,
  });

  final String title;
  final String value;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              footer,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onTap});

  final EvaluationSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Color(session.colorHex).withValues(alpha: 0.12),
          child: Icon(
            mapMaterialSymbol(session.icon),
            color: Color(session.colorHex),
          ),
        ),
        title: Text(
          session.scenarioTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(session.date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${session.avgScore.toStringAsFixed(1)}/5.0',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
