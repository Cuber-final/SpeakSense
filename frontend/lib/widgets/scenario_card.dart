import 'package:flutter/material.dart';
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

    return Opacity(
      opacity: scenario.isLocked ? 0.75 : 1,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: scenario.isLocked ? null : onTap,
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
                    if (!scenario.isLocked)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            scenario.level.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
                    Row(
                      children: <Widget>[
                        if (!scenario.isLocked) ...<Widget>[
                          Icon(
                            Icons.quiz_outlined,
                            size: 16,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${scenario.questionCount} Questions',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: onTap,
                            child: const Text('Start'),
                          ),
                        ] else ...<Widget>[
                          Text(
                            'Premium',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: null,
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
    );
  }
}
