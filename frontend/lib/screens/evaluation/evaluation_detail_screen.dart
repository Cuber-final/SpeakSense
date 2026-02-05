import 'package:flutter/material.dart';
import 'package:speaksense_app/data/mock_data.dart';

class EvaluationDetailScreen extends StatelessWidget {
  const EvaluationDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(scaffoldBackgroundColor: const Color(0xFF0F1423)),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1423),
          foregroundColor: Colors.white,
          title: const Text('Coffee Shop Ordering - Evaluation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('PDF'),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const _TopMetrics(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Question Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuestionItem(
                    dimensions: const <_DimensionBar>[
                      _DimensionBar(
                        label: 'Relevance',
                        score: 4.8,
                        color: Color(0xFF10B981),
                      ),
                      _DimensionBar(
                        label: 'Naturalness',
                        score: 2.5,
                        color: Color(0xFFF97316),
                      ),
                      _DimensionBar(
                        label: 'Grammar',
                        score: 3.8,
                        color: Color(0xFF3B82F6),
                      ),
                      _DimensionBar(
                        label: 'Richness',
                        score: 3.2,
                        color: Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMetrics extends StatelessWidget {
  const _TopMetrics();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final bool stacked = constraints.maxWidth < 980;
        if (stacked) {
          return const Column(
            children: <Widget>[
              _OverallScoreCard(),
              SizedBox(height: 12),
              _DimensionsCard(),
              SizedBox(height: 12),
              _MiniMetricsColumn(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 4, child: _OverallScoreCard()),
            SizedBox(width: 12),
            Expanded(flex: 4, child: _DimensionsCard()),
            SizedBox(width: 12),
            Expanded(flex: 3, child: _MiniMetricsColumn()),
          ],
        );
      },
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const CircularProgressIndicator(
                  value: 0.7,
                  strokeWidth: 12,
                  backgroundColor: Color(0xFF1F2937),
                  color: Color(0xFF2962FF),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Text(
                      '3.5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('Overall', style: TextStyle(color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Intermediate High',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Great job! You are clearly understood by native speakers in most contexts.',
            style: TextStyle(color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DimensionsCard extends StatelessWidget {
  const _DimensionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Performance Dimensions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final dimension in kScoreDimensions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DimensionBar(
                label: dimension.label,
                score: dimension.score,
                color: const Color(0xFF2962FF),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniMetricsColumn extends StatelessWidget {
  const _MiniMetricsColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        _MiniMetric(
          icon: Icons.timer_rounded,
          title: 'Duration',
          value: '14m 32s',
        ),
        SizedBox(height: 8),
        _MiniMetric(icon: Icons.speed_rounded, title: 'Pace', value: '115 wpm'),
        SizedBox(height: 8),
        _MiniMetric(
          icon: Icons.psychology_rounded,
          title: 'Vocabulary',
          value: 'B2 Level',
        ),
      ],
    );
  }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF60A5FA)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionItem extends StatelessWidget {
  const _QuestionItem({required this.dimensions});

  final List<_DimensionBar> dimensions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1423),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '"How would you order a latte with oat milk?"',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your Answer: "Can I get a latte? Uhm, I want oat milk inside. And make it hot please."',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            for (final _DimensionBar bar in dimensions)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: bar),
            const SizedBox(height: 8),
            const Text(
              'AI Feedback: Clear request, but "oat milk inside" sounds unnatural.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(label, style: const TextStyle(color: Color(0xFFCBD5E1))),
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
          backgroundColor: const Color(0xFF1F2937),
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}
