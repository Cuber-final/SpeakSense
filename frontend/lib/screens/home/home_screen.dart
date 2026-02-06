import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speaksense_app/models/scenario.dart';
import 'package:speaksense_app/services/content_repository.dart';
import 'package:speaksense_app/widgets/data_source_banner.dart';
import 'package:speaksense_app/widgets/scenario_card.dart';
import 'package:speaksense_app/widgets/state_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.useMockApi,
    required this.onOpenPractice,
    super.key,
  });

  final bool useMockApi;
  final VoidCallback onOpenPractice;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Scenario> _scenarios = const <Scenario>[];
  String? _notice;
  bool _fromMock = true;
  bool _isLoading = true;
  ScenarioCategory? _category;

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useMockApi != widget.useMockApi) {
      _loadScenarios();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScenarios() async {
    setState(() {
      _isLoading = true;
    });

    final ContentRepository repository = context.read<ContentRepository>();
    final RepositoryPayload<List<Scenario>> payload = await repository
        .loadScenarios(useMockApi: widget.useMockApi);

    if (!mounted) {
      return;
    }
    setState(() {
      _scenarios = payload.data;
      _fromMock = payload.fromMock;
      _notice = payload.notice;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String query = _searchController.text.toLowerCase();
    final List<Scenario> filtered = _scenarios.where((Scenario scenario) {
      final bool byCategory =
          _category == null || scenario.category == _category;
      final bool byQuery =
          scenario.title.toLowerCase().contains(query) ||
          scenario.description.toLowerCase().contains(query);
      return byCategory && byQuery;
    }).toList();
    final int columns = switch (MediaQuery.of(context).size.width) {
      < 700 => 1,
      < 1100 => 2,
      _ => 3,
    };

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search practice scenarios...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _loadScenarios,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                DataSourceBanner(fromMock: _fromMock, notice: _notice),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilterChip(
                      selected: _category == null,
                      label: const Text('All Scenarios'),
                      onSelected: (_) => setState(() => _category = null),
                    ),
                    for (final ScenarioCategory item in ScenarioCategory.values)
                      FilterChip(
                        selected: _category == item,
                        label: Text(item.label),
                        onSelected: (_) => setState(() => _category = item),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  StatePanel.loading(
                    title: '加载场景中...',
                    description: '正在获取最新的练习场景，请稍候。',
                  )
                else if (filtered.isEmpty)
                  StatePanel.empty(
                    title: '暂无匹配场景',
                    description: '尝试切换分类或刷新列表。',
                    actionLabel: '重新加载',
                    onAction: _loadScenarios,
                  )
                else
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          const double spacing = 16;
                          final double itemWidth =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: <Widget>[
                              for (final Scenario scenario in filtered)
                                SizedBox(
                                  width: itemWidth,
                                  child: ScenarioCard(
                                    scenario: scenario,
                                    onTap: widget.onOpenPractice,
                                  ),
                                ),
                            ],
                          );
                        },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
