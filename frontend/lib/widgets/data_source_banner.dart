import 'package:flutter/material.dart';

class DataSourceBanner extends StatelessWidget {
  const DataSourceBanner({required this.fromMock, this.notice, super.key});

  final bool fromMock;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MaterialColor baseTone = fromMock ? Colors.amber : Colors.green;
    final String label = fromMock ? 'Mock 数据源' : 'API 数据源';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: baseTone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseTone.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            fromMock ? Icons.science_rounded : Icons.cloud_done_rounded,
            size: 18,
            color: baseTone.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notice == null ? '当前使用: $label' : '$label · $notice',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: baseTone.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
