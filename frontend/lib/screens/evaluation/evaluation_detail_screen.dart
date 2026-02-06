import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:speaksense_app/models/evaluation_detail.dart';
import 'package:speaksense_app/models/evaluation_session.dart';
import 'package:speaksense_app/services/content_repository.dart';
import 'package:speaksense_app/widgets/data_source_banner.dart';
import 'package:speaksense_app/widgets/state_panel.dart';

BoxDecoration _cardDecoration(
  ThemeData theme, {
  double radius = 16,
}) {
  return BoxDecoration(
    color: theme.cardTheme.color ?? theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: theme.colorScheme.outline.withValues(alpha: 0.6),
    ),
  );
}

BoxDecoration _panelDecoration(
  ThemeData theme, {
  double radius = 14,
}) {
  return BoxDecoration(
    color: theme.colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: theme.colorScheme.outline.withValues(alpha: 0.5),
    ),
  );
}

class EvaluationDetailScreen extends StatefulWidget {
  const EvaluationDetailScreen({
    required this.sessionId,
    required this.useMockApi,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  final String sessionId;
  final bool useMockApi;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<EvaluationDetailScreen> createState() => _EvaluationDetailScreenState();
}

class _EvaluationDetailScreenState extends State<EvaluationDetailScreen> {
  EvaluationDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _fromMock = true;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void didUpdateWidget(covariant EvaluationDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.useMockApi != widget.useMockApi) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ContentRepository repository = context.read<ContentRepository>();
    final RepositoryPayload<EvaluationDetail> payload = await repository
        .loadEvaluationDetail(
          sessionId: widget.sessionId,
          useMockApi: widget.useMockApi,
        );

    if (!mounted) {
      return;
    }
    setState(() {
      _detail = payload.data;
      _fromMock = payload.fromMock;
      _notice = payload.notice;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (widget.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatePanel.loading(
              title: '加载评估详情...',
              description: '正在同步评分与反馈内容。',
            ),
          ),
        ),
      );
    }

    if (widget.errorMessage != null &&
        widget.errorMessage!.trim().isNotEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatePanel.error(
              title: '评估详情加载失败',
              description: widget.errorMessage!,
              actionLabel: widget.onRetry == null ? null : '重试',
              onAction: widget.onRetry,
            ),
          ),
        ),
      );
    }

    if (_isLoading || _detail == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatePanel.loading(
              title: '加载评估详情...',
              description: '正在同步评分与反馈内容。',
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatePanel.error(
              title: '评估详情加载失败',
              description: _errorMessage!,
              actionLabel: '重试',
              onAction: _loadDetail,
            ),
          ),
        ),
      );
    }

    final EvaluationDetail detail = _detail!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${detail.scenarioTitle} - Evaluation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          FButton(
            onPress: () {},
            style: FButtonStyle.outline(),
            prefix: const Icon(Icons.download_rounded),
            child: const Text('PDF'),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FButton(
              onPress: () {},
              prefix: const Icon(Icons.share_rounded),
              child: const Text('Share'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          if (_notice != null || _fromMock)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DataSourceBanner(fromMock: _fromMock, notice: _notice),
            ),
          _TopMetrics(detail: detail),
          const SizedBox(height: 20),
          FCard.raw(
            style: (FCardStyle style) => style.copyWith(
              decoration: _cardDecoration(theme),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Question Breakdown',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuestionBreakdownList(questions: detail.questions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMetrics extends StatelessWidget {
  const _TopMetrics({required this.detail});

  final EvaluationDetail detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final bool stacked = constraints.maxWidth < 980;
        if (stacked) {
          return Column(
            children: <Widget>[
              _OverallScoreCard(detail: detail),
              SizedBox(height: 12),
              _DimensionsCard(dimensions: detail.dimensions),
              SizedBox(height: 12),
              _MiniMetricsColumn(metrics: detail.metrics),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 4, child: _OverallScoreCard(detail: detail)),
            SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _DimensionsCard(dimensions: detail.dimensions),
            ),
            SizedBox(width: 12),
            Expanded(flex: 3, child: _MiniMetricsColumn(metrics: detail.metrics)),
          ],
        );
      },
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard({required this.detail});

  final EvaluationDetail detail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final double scoreFontSize =
        theme.textTheme.displaySmall?.fontSize ?? 42;
    final double ringSize = scoreFontSize * 8;
    final double ringStroke =
        (scoreFontSize * 0.24).clamp(8.0, 14.0).toDouble();
    final double progress = (detail.overallScore / 5).clamp(0, 1);
    return FCard.raw(
      style: (FCardStyle style) => style.copyWith(
        decoration: _cardDecoration(theme),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            SizedBox.square(
              dimension: ringSize,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: <Widget>[
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: ringStroke,
                    backgroundColor:
                        theme.colorScheme.outline.withValues(alpha: 0.45),
                    color: theme.colorScheme.primary,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          detail.overallScore.toStringAsFixed(1),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Overall',
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              detail.level,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail.summary,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionsCard extends StatefulWidget {
  const _DimensionsCard({required this.dimensions});

  final List<ScoreDimension> dimensions;

  @override
  State<_DimensionsCard> createState() => _DimensionsCardState();
}

class _DimensionsCardState extends State<_DimensionsCard> {
  static const double _maxScore = 5;

  bool _isInteracting = false;

  List<RadarEntry> _buildEntries(double value) {
    return List<RadarEntry>.generate(
      widget.dimensions.length,
      (_) => RadarEntry(value: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color chartColor = theme.colorScheme.primary;
    final Color gridColor = theme.colorScheme.outline.withValues(alpha: 0.6);
    final Color labelColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final Color tickColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.45);

    if (widget.dimensions.length < 3) {
      return FCard.raw(
        style: (FCardStyle style) => style.copyWith(
          decoration: _cardDecoration(theme),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Performance Dimensions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '暂无维度评分数据。',
                style: theme.textTheme.bodyMedium?.copyWith(color: labelColor),
              ),
            ],
          ),
        ),
      );
    }
    return FCard.raw(
      style: (FCardStyle style) => style.copyWith(
        decoration: _cardDecoration(theme),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Performance Dimensions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool stacked = constraints.maxWidth < 520;
                final Widget radarChart = AspectRatio(
                  aspectRatio: stacked ? 1.2 : 1.1,
                  child: RadarChart(
                    RadarChartData(
                      radarTouchData: RadarTouchData(
                        touchCallback: (
                          FlTouchEvent event,
                          RadarTouchResponse? response,
                        ) {
                          final bool isTouching = event
                                  .isInterestedForInteractions &&
                              response?.touchedSpot != null;
                          if (_isInteracting != isTouching) {
                            setState(() => _isInteracting = isTouching);
                          }
                        },
                      ),
                      dataSets: <RadarDataSet>[
                        RadarDataSet(
                          fillColor: chartColor.withValues(
                            alpha: _isInteracting ? 0.35 : 0.22,
                          ),
                          borderColor: chartColor.withValues(
                            alpha: _isInteracting ? 1 : 0.7,
                          ),
                          borderWidth: _isInteracting ? 2.4 : 2,
                          entryRadius: _isInteracting ? 4 : 3,
                          dataEntries: widget.dimensions
                              .map((ScoreDimension dimension) =>
                                  RadarEntry(value: dimension.score))
                              .toList(),
                        ),
                        RadarDataSet(
                          fillColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          borderWidth: 0,
                          entryRadius: 0,
                          dataEntries: _buildEntries(0),
                        ),
                        RadarDataSet(
                          fillColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          borderWidth: 0,
                          entryRadius: 0,
                          dataEntries: _buildEntries(_maxScore),
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      radarBorderData:
                          BorderSide(color: gridColor, width: 1.4),
                      gridBorderData: BorderSide(color: gridColor, width: 1),
                      tickBorderData: BorderSide(color: gridColor, width: 1),
                      tickCount: 4,
                      ticksTextStyle: TextStyle(
                        color: tickColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      getTitle: (int index, double angle) {
                        if (index >= widget.dimensions.length) {
                          return const RadarChartTitle(text: '');
                        }
                        return RadarChartTitle(
                          text: widget.dimensions[index].label,
                          angle: angle,
                        );
                      },
                      titleTextStyle: TextStyle(
                        color: labelColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      titlePositionPercentageOffset: 0.18,
                      radarShape: RadarShape.polygon,
                      borderData: FlBorderData(show: false),
                    ),
                    duration: const Duration(milliseconds: 350),
                  ),
                );
                final Widget legend = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.dimensions
                      .map((ScoreDimension dimension) => _DimensionLegendItem(
                            dimension: dimension,
                            color: chartColor,
                          ))
                      .toList(),
                );

                if (stacked) {
                  return Column(
                    children: <Widget>[
                      radarChart,
                      const SizedBox(height: 12),
                      legend,
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    Expanded(child: radarChart),
                    const SizedBox(width: 16),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionLegendItem extends StatelessWidget {
  const _DimensionLegendItem({
    required this.dimension,
    required this.color,
  });

  final ScoreDimension dimension;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted =
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dimension.label,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          Text(
            '${dimension.score.toStringAsFixed(1)} / 5',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricsColumn extends StatelessWidget {
  const _MiniMetricsColumn({required this.metrics});

  final List<EvaluationMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final List<EvaluationMetric> displayMetrics = metrics.isEmpty
        ? const <EvaluationMetric>[]
        : metrics.take(3).toList();
    return Column(
      children: <Widget>[
        for (int i = 0; i < displayMetrics.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == displayMetrics.length - 1 ? 0 : 8),
            child: _MiniMetric(
              icon: _metricIcon(displayMetrics[i]),
              title: displayMetrics[i].label,
              value: displayMetrics[i].value,
            ),
          ),
      ],
    );
  }
}

IconData _metricIcon(EvaluationMetric metric) {
  final String key = (metric.key ?? metric.label).toLowerCase();
  if (key.contains('duration') || key.contains('time')) {
    return Icons.timer_rounded;
  }
  if (key.contains('pace') || key.contains('speed') || key.contains('wpm')) {
    return Icons.speed_rounded;
  }
  if (key.contains('vocab') || key.contains('lex')) {
    return Icons.psychology_rounded;
  }
  return Icons.insights_rounded;
}

Color _dimensionColor(String label, ThemeData theme) {
  final String key = label.toLowerCase();
  if (key.contains('relevance')) {
    return const Color(0xFF10B981);
  }
  if (key.contains('natural')) {
    return const Color(0xFFF97316);
  }
  if (key.contains('grammar')) {
    return const Color(0xFF3B82F6);
  }
  if (key.contains('rich')) {
    return const Color(0xFF6366F1);
  }
  return theme.colorScheme.primary;
}

double _progressValue(Duration position, Duration duration) {
  if (duration.inMilliseconds == 0) {
    return 0;
  }
  final double value =
      position.inMilliseconds / duration.inMilliseconds;
  if (value.isNaN || value.isInfinite) {
    return 0;
  }
  return value.clamp(0, 1);
}

String _formatDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return FCard.raw(
      style: (FCardStyle style) => style.copyWith(
        decoration: _cardDecoration(theme, radius: 14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBreakdownList extends StatefulWidget {
  const _QuestionBreakdownList({required this.questions});

  final List<EvaluationQuestion> questions;

  @override
  State<_QuestionBreakdownList> createState() => _QuestionBreakdownListState();
}

class _QuestionBreakdownListState extends State<_QuestionBreakdownList> {
  final Set<int> _expanded = <int>{0};
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  int? _activeIndex;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _positionSub = _player.positionStream.listen((Duration position) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = position;
      });
    });
    _durationSub = _player.durationStream.listen((Duration? duration) {
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = duration ?? Duration.zero;
      });
    });
    _stateSub = _player.playerStateStream.listen((PlayerState state) {
      if (!mounted) {
        return;
      }
      final bool buffering = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      setState(() {
        _isPlaying = state.playing;
        _isBuffering = buffering;
      });
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  Future<void> _togglePlayback({
    required int index,
    required String? audioUrl,
  }) async {
    final String url = audioUrl?.trim() ?? '';
    if (url.isEmpty) {
      _showAudioToast('Audio unavailable');
      return;
    }
    if (_activeIndex != index) {
      setState(() {
        _activeIndex = index;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      try {
        await _player.setUrl(url);
        await _player.play();
      } catch (_) {
        if (!mounted) {
          return;
        }
        _showAudioToast('音频播放失败');
      }
      return;
    }
    if (_isPlaying) {
      await _player.pause();
    } else {
      try {
        await _player.play();
      } catch (_) {
        if (!mounted) {
          return;
        }
        _showAudioToast('音频播放失败');
      }
    }
  }

  void _showAudioToast(String title) {
    showFToast(
      context: context,
      title: Text(title),
      icon: const Icon(Icons.info_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return StatePanel.empty(
        title: '暂无题目细分',
        description: '评估完成后会在这里展示问题反馈。',
      );
    }
    return Column(
      children: <Widget>[
        for (int i = 0; i < widget.questions.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == widget.questions.length - 1 ? 0 : 12,
            ),
            child: _QuestionItemCard(
              index: i,
              data: widget.questions[i],
              isExpanded: _expanded.contains(i),
              onToggle: () => _toggle(i),
              isActive: _activeIndex == i,
              isPlaying: _activeIndex == i && _isPlaying,
              isBuffering: _activeIndex == i && _isBuffering,
              elapsed: _formatDuration(
                _activeIndex == i ? _position : Duration.zero,
              ),
              total: _formatDuration(
                _activeIndex == i ? _duration : Duration.zero,
              ),
              progress: _progressValue(
                _activeIndex == i ? _position : Duration.zero,
                _activeIndex == i ? _duration : Duration.zero,
              ),
              onPlayToggle: () => _togglePlayback(
                index: i,
                audioUrl: widget.questions[i].audioUrl,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuestionItemCard extends StatelessWidget {
  const _QuestionItemCard({
    required this.index,
    required this.data,
    required this.isExpanded,
    required this.onToggle,
    required this.isActive,
    required this.isPlaying,
    required this.isBuffering,
    required this.progress,
    required this.elapsed,
    required this.total,
    required this.onPlayToggle,
  });

  final int index;
  final EvaluationQuestion data;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isActive;
  final bool isPlaying;
  final bool isBuffering;
  final double progress;
  final String elapsed;
  final String total;
  final VoidCallback onPlayToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final Color dividerColor =
        theme.colorScheme.outline.withValues(alpha: 0.4);
    return FCard.raw(
      style: (FCardStyle style) => style.copyWith(
        decoration: _panelDecoration(theme),
      ),
      child: Column(
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            data.prompt,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isExpanded
                                ? 'Tap to collapse details'
                                : 'Tap to expand details',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: <Widget>[
                Divider(height: 1, thickness: 1, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: _QuestionItemDetail(
                    data: data,
                    isActive: isActive,
                    isPlaying: isPlaying,
                    isBuffering: isBuffering,
                    progress: progress,
                    elapsed: elapsed,
                    total: total,
                    onPlayToggle: onPlayToggle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionItemDetail extends StatelessWidget {
  const _QuestionItemDetail({
    required this.data,
    required this.isActive,
    required this.isPlaying,
    required this.isBuffering,
    required this.progress,
    required this.elapsed,
    required this.total,
    required this.onPlayToggle,
  });

  final EvaluationQuestion data;
  final bool isActive;
  final bool isPlaying;
  final bool isBuffering;
  final double progress;
  final String elapsed;
  final String total;
  final VoidCallback onPlayToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final Color panelFill =
        theme.colorScheme.primary.withValues(alpha: 0.06);
    final Color panelBorder =
        theme.colorScheme.outline.withValues(alpha: 0.5);

    Future<void> copySuggestion() async {
      await Clipboard.setData(ClipboardData(text: data.suggestedAnswer));
      if (!context.mounted) {
        return;
      }
      showFToast(
        context: context,
        title: const Text('Suggested answer copied'),
        description: const Text('You can paste it into your notes.'),
        icon: const Icon(Icons.check_circle_rounded),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Your Answer:',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '"${data.answer}"',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        if (data.audioUrl != null && data.audioUrl!.trim().isNotEmpty)
          _AudioReplayRow(
            progress: progress,
            elapsed: elapsed,
            total: total,
            isPlaying: isPlaying,
            isBuffering: isBuffering,
            onToggle: onPlayToggle,
          )
        else
          Text(
            'Audio unavailable',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        const SizedBox(height: 12),
        for (final ScoreDimension dimension in data.dimensions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DimensionBar(
              label: dimension.label,
              score: dimension.score,
              color: _dimensionColor(dimension.label, theme),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'AI Feedback:',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          data.feedback,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        if (data.suggestedAnswer.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                'Suggested Answer',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FButton(
                style: FButtonStyle.outline(),
                onPress: copySuggestion,
                prefix: const Icon(Icons.copy_rounded, size: 16),
                child: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: panelFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: panelBorder),
            ),
            child: Text(
              data.suggestedAnswer,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ],
    );
  }
}

class _AudioReplayRow extends StatelessWidget {
  const _AudioReplayRow({
    required this.progress,
    required this.elapsed,
    required this.total,
    required this.isPlaying,
    required this.isBuffering,
    required this.onToggle,
  });

  final double progress;
  final String elapsed;
  final String total;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final Widget icon = isBuffering
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: theme.colorScheme.primary,
              backgroundColor:
                  theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          )
        : Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: theme.colorScheme.primary,
          );
    return Row(
      children: <Widget>[
        InkResponse(
          onTap: onToggle,
          radius: 28,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor:
                    theme.colorScheme.outline.withValues(alpha: 0.25),
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Text(
                    elapsed,
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                  const Spacer(),
                  Text(
                    total,
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DimensionBar extends StatelessWidget {
  const _DimensionBar({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted =
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const Spacer(),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 5,
          color: color,
          backgroundColor:
              theme.colorScheme.outline.withValues(alpha: 0.35),
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}
