import 'package:flutter/material.dart';

enum StatePanelVariant { loading, empty, error }

class StatePanel extends StatelessWidget {
  const StatePanel({
    required this.variant,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final StatePanelVariant variant;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  factory StatePanel.loading({
    required String title,
    required String description,
  }) {
    return StatePanel(
      variant: StatePanelVariant.loading,
      title: title,
      description: description,
    );
  }

  factory StatePanel.empty({
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return StatePanel(
      variant: StatePanelVariant.empty,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory StatePanel.error({
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return StatePanel(
      variant: StatePanelVariant.error,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tone = switch (variant) {
      StatePanelVariant.loading => theme.colorScheme.primary,
      StatePanelVariant.empty => theme.hintColor,
      StatePanelVariant.error => theme.colorScheme.error,
    };
    final IconData icon = switch (variant) {
      StatePanelVariant.loading => Icons.hourglass_top_rounded,
      StatePanelVariant.empty => Icons.inbox_rounded,
      StatePanelVariant.error => Icons.error_outline_rounded,
    };
    final bool showAction = actionLabel != null && onAction != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (variant == StatePanelVariant.loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          if (showAction) ...<Widget>[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
