import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:speaksense_app/models/evaluation_session.dart';
import 'package:speaksense_app/services/content_repository.dart';
import 'package:speaksense_app/utils/material_icon_mapper.dart';
import 'package:speaksense_app/widgets/data_source_banner.dart';
import 'package:speaksense_app/widgets/state_panel.dart';

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
              FButton(
                onPress: _loadSessions,
                prefix: const Icon(Icons.add_rounded),
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DataSourceBanner(fromMock: _fromMock, notice: _notice),
          const SizedBox(height: 14),
          const _StatsRow(),
          const SizedBox(height: 20),
          FCard.raw(
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
                      FButton(
                        onPress: () {},
                        style: FButtonStyle.outline(),
                        child: const Text('Last 30 Days'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    StatePanel.loading(
                      title: '加载评估记录...',
                      description: '正在同步最近的练习评估。',
                    )
                  else if (_sessions.isEmpty)
                    StatePanel.empty(
                      title: '暂无评估记录',
                      description: '完成一次练习后会在这里看到评分。',
                      actionLabel: '刷新列表',
                      onAction: _loadSessions,
                    )
                  else
                    FItemGroup.group(
                      physics: const NeverScrollableScrollPhysics(),
                      divider: FItemDivider.indented,
                      children: <FItem>[
                        for (final EvaluationSession session in _sessions)
                          FItem(
                            onPress: () => widget.onOpenDetail(session.id),
                            prefix: CircleAvatar(
                              backgroundColor:
                                  Color(session.colorHex).withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(
                                mapMaterialSymbol(session.icon),
                                color: Color(session.colorHex),
                              ),
                            ),
                            title: Text(
                              session.scenarioTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(session.date),
                            details: Text(
                              '${session.avgScore.toStringAsFixed(1)}/5.0',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            suffix: const Icon(Icons.chevron_right_rounded),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FCard.raw(
            style: (FCardStyle style) => style.copyWith(
              decoration: style.decoration.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
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
    return FCard.raw(
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
