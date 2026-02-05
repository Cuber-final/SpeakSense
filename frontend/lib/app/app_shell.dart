import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speaksense_app/app/app_state.dart';
import 'package:speaksense_app/screens/evaluation/evaluation_detail_screen.dart';
import 'package:speaksense_app/screens/evaluation/evaluation_list_screen.dart';
import 'package:speaksense_app/screens/home/home_screen.dart';
import 'package:speaksense_app/screens/practice/practice_screen.dart';
import 'package:speaksense_app/screens/wordbook/wordbook_screen.dart';
import 'package:speaksense_app/services/websocket_service.dart';

enum AppTab { home, practice, evaluation, wordbook }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.home;
  StreamSubscription<RealtimeEvent>? _wsSubscription;
  _EvaluationBannerData? _bannerData;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    final WebSocketService ws = context.read<WebSocketService>();
    ws.start();
    _wsSubscription = ws.events.listen(_handleRealtimeEvent);
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _setTab(AppTab tab) {
    setState(() {
      _tab = tab;
    });
  }

  void _openEvaluationDetail(String sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EvaluationDetailScreen(sessionId: sessionId),
      ),
    );
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (!event.isEvaluationCompleted) {
      return;
    }
    _bannerTimer?.cancel();
    setState(() {
      _bannerData = _EvaluationBannerData(
        attemptId: event.attemptId,
        message: event.message ?? '你的口语评估已完成，点击查看详情。',
      );
    });
    _bannerTimer = Timer(const Duration(seconds: 8), _dismissBanner);
  }

  void _dismissBanner() {
    if (!mounted) {
      return;
    }
    setState(() {
      _bannerData = null;
    });
  }

  void _onBannerTap() {
    final _EvaluationBannerData? data = _bannerData;
    if (data == null) {
      return;
    }
    _dismissBanner();
    _setTab(AppTab.evaluation);
    if (data.attemptId != null) {
      _openEvaluationDetail(data.attemptId!);
    }
  }

  Widget _buildCurrentPage(bool useMockApi) {
    return switch (_tab) {
      AppTab.home => HomeScreen(
        useMockApi: useMockApi,
        onOpenPractice: () => _setTab(AppTab.practice),
      ),
      AppTab.practice => PracticeScreen(
        useMockApi: useMockApi,
        onExit: () => _setTab(AppTab.home),
        onSubmit: () => _openEvaluationDetail('1'),
      ),
      AppTab.evaluation => EvaluationListScreen(
        useMockApi: useMockApi,
        onOpenDetail: _openEvaluationDetail,
      ),
      AppTab.wordbook => WordbookScreen(useMockApi: useMockApi),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppState appState = context.watch<AppState>();
    final bool useMockApi = appState.useMockApi;
    final bool desktop = MediaQuery.of(context).size.width >= 960;

    if (desktop) {
      return Stack(
        children: <Widget>[
          Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Row(
              children: <Widget>[
                _DesktopSidebar(tab: _tab, onSelect: _setTab),
                Expanded(child: _buildCurrentPage(useMockApi)),
              ],
            ),
          ),
          _EvaluationCompletedBanner(
            data: _bannerData,
            onTap: _onBannerTap,
            onDismiss: _dismissBanner,
          ),
          if (kDebugMode) const _DeveloperMenu(),
        ],
      );
    }

    return Stack(
      children: <Widget>[
        Scaffold(
          body: _buildCurrentPage(useMockApi),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab.index,
            onDestinationSelected: (int value) => _setTab(AppTab.values[value]),
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_rounded),
                label: '首页',
              ),
              NavigationDestination(icon: Icon(Icons.mic_rounded), label: '练习'),
              NavigationDestination(
                icon: Icon(Icons.analytics_rounded),
                label: '评估',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_rounded),
                label: '词本',
              ),
            ],
          ),
        ),
        _EvaluationCompletedBanner(
          data: _bannerData,
          onTap: _onBannerTap,
          onDismiss: _dismissBanner,
        ),
        if (kDebugMode) const _DeveloperMenu(),
      ],
    );
  }
}

enum _DeveloperAction { toggleMockSource, emitEvaluationCompleted }

class _DeveloperMenu extends StatelessWidget {
  const _DeveloperMenu();

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: PopupMenuButton<_DeveloperAction>(
              tooltip: '开发者设置',
              icon: const Icon(Icons.developer_mode_rounded),
              onSelected: (_DeveloperAction action) {
                if (action == _DeveloperAction.toggleMockSource) {
                  context.read<AppState>().setUseMockApi(!appState.useMockApi);
                }
                if (action == _DeveloperAction.emitEvaluationCompleted) {
                  context
                      .read<WebSocketService>()
                      .emitDebugEvaluationCompleted();
                }
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<_DeveloperAction>>[
                    PopupMenuItem<_DeveloperAction>(
                      enabled: false,
                      child: Text(
                        'Base URL: ${appState.apiBaseUrl}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CheckedPopupMenuItem<_DeveloperAction>(
                      value: _DeveloperAction.toggleMockSource,
                      checked: appState.useMockApi,
                      child: const Text('使用 Mock API'),
                    ),
                    const PopupMenuItem<_DeveloperAction>(
                      value: _DeveloperAction.emitEvaluationCompleted,
                      child: Text('模拟 evaluation.completed'),
                    ),
                  ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvaluationBannerData {
  const _EvaluationBannerData({required this.message, this.attemptId});

  final String message;
  final String? attemptId;
}

class _EvaluationCompletedBanner extends StatelessWidget {
  const _EvaluationCompletedBanner({
    required this.data,
    required this.onTap,
    required this.onDismiss,
  });

  final _EvaluationBannerData? data;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final bool isVisible = data != null;
    final ThemeData theme = Theme.of(context);

    return IgnorePointer(
      ignoring: !isVisible,
      child: SafeArea(
        child: AnimatedSlide(
          offset: isVisible ? Offset.zero : const Offset(0, -1.2),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 620),
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              data?.message ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onTap,
                            child: const Text(
                              '查看',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            onPressed: onDismiss,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.tab, required this.onSelect});

  final AppTab tab;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color selectedColor = theme.colorScheme.primary;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                ),
              ),
              title: const Text(
                'SpeakSense',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('AI English Coach'),
            ),
            const SizedBox(height: 12),
            _DesktopNavItem(
              isActive: tab == AppTab.home,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => onSelect(AppTab.home),
            ),
            _DesktopNavItem(
              isActive: tab == AppTab.practice,
              icon: Icons.mic_rounded,
              label: 'Practice',
              onTap: () => onSelect(AppTab.practice),
            ),
            _DesktopNavItem(
              isActive: tab == AppTab.evaluation,
              icon: Icons.analytics_rounded,
              label: 'Evaluation',
              onTap: () => onSelect(AppTab.evaluation),
            ),
            _DesktopNavItem(
              isActive: tab == AppTab.wordbook,
              icon: Icons.menu_book_rounded,
              label: 'Wordbook',
              onTap: () => onSelect(AppTab.wordbook),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade400,
                child: const Text('A', style: TextStyle(color: Colors.white)),
              ),
              title: const Text('Alex Morgan'),
              subtitle: const Text('Premium Plan'),
              trailing: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.isActive,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isActive;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color active = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive ? active : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(icon, color: isActive ? Colors.white : theme.hintColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
