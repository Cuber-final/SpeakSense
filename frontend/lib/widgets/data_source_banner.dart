import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class DataSourceBanner extends StatelessWidget {
  const DataSourceBanner({required this.fromMock, this.notice, super.key});

  final bool fromMock;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MaterialColor baseTone = fromMock ? Colors.amber : Colors.green;
    final String label = fromMock ? 'Mock 数据源' : 'API 数据源';

    return FCard.raw(
      style: (FCardStyle style) => style.copyWith(
        decoration: style.decoration.copyWith(
          color: baseTone.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: baseTone.withValues(alpha: 0.3)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            FBadge(
              style: FBadgeStyle.outline(
                (FBadgeStyle style) => style.copyWith(
                  decoration: style.decoration.copyWith(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: baseTone.withValues(alpha: 0.5)),
                  ),
                  contentStyle: (FBadgeContentStyle contentStyle) =>
                      contentStyle.copyWith(
                        labelTextStyle: contentStyle.labelTextStyle.copyWith(
                          color: baseTone.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                      ),
                ),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
