import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:speaksense_app/models/scenario.dart';
import 'package:speaksense_app/utils/material_icon_mapper.dart';

class ScenarioCard extends StatelessWidget {
  const ScenarioCard({required this.scenario, required this.onTap, super.key});

  final Scenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = Color(scenario.colorHex);
    final BorderRadius borderRadius =
        (context.theme.cardStyle.decoration.borderRadius?.resolve(
              Directionality.of(context),
            )) ??
            BorderRadius.circular(12);

    return Opacity(
      opacity: scenario.isLocked ? 0.75 : 1,
      child: FCard.raw(
        child: ClipRRect(
          borderRadius: borderRadius,
          child: FTappable.static(
            onPress: scenario.isLocked ? null : onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        accent.withValues(alpha: 0.28),
                        theme.colorScheme.surface,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Center(
                        child: Icon(
                          mapMaterialSymbol(scenario.icon),
                          size: 52,
                          color: accent,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: FBadge(
                          style: FBadgeStyle.secondary(
                            (FBadgeStyle style) => style.copyWith(
                              decoration: style.decoration.copyWith(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.25),
                                ),
                              ),
                              contentStyle: (FBadgeContentStyle contentStyle) =>
                                  contentStyle.copyWith(
                                    labelTextStyle: contentStyle.labelTextStyle
                                        .copyWith(
                                          color: accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                            ),
                          ),
                          child: Text(scenario.level.label),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        scenario.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scenario.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FItemGroup.group(
                        physics: const NeverScrollableScrollPhysics(),
                        divider: FItemDivider.none,
                        style: (FItemGroupStyle style) => style.copyWith(
                          decoration: const BoxDecoration(),
                          spacing: 0,
                          dividerWidth: 0,
                          itemStyle: (FItemStyle itemStyle) =>
                              itemStyle.copyWith(
                                margin: EdgeInsets.zero,
                                backgroundColor: FWidgetStateMap.all(
                                  Colors.transparent,
                                ),
                                decoration: FWidgetStateMap.all(
                                  BoxDecoration(color: Colors.transparent),
                                ),
                                contentStyle: (FItemContentStyle contentStyle) =>
                                    contentStyle.copyWith(
                                      padding: EdgeInsets.zero,
                                      prefixIconSpacing: 6,
                                      titleTextStyle:
                                          FWidgetStateMap.all(
                                        (theme.textTheme.labelMedium ??
                                                const TextStyle())
                                            .copyWith(
                                              color: theme.hintColor,
                                            ),
                                      ),
                                      prefixIconStyle:
                                          FWidgetStateMap.all(
                                        IconThemeData(
                                          color: theme.hintColor,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                              ),
                        ),
                        children: <FItem>[
                          FItem(
                            title: Text(
                              '${scenario.questionCount} Questions',
                            ),
                            prefix: const Icon(Icons.quiz_outlined),
                          ),
                          FItem(
                            title: Text(scenario.category.label),
                            prefix: const Icon(Icons.label_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          if (!scenario.isLocked) ...<Widget>[
                            FButton(
                              onPress: onTap,
                              child: const Text('Start'),
                            ),
                            const Spacer(),
                            FBadge(
                              style: FBadgeStyle.outline(),
                              child: const Text('Available'),
                            ),
                          ] else ...<Widget>[
                            FBadge(
                              style: FBadgeStyle.outline(),
                              child: const Text('Premium'),
                            ),
                            const Spacer(),
                            FButton(
                              onPress: null,
                              style: FButtonStyle.outline(),
                              child: const Text('Locked'),
                            ),
                          ],
                        ],
                      ),
                    ],
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
