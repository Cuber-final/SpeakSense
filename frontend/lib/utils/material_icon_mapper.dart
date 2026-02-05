import 'package:flutter/material.dart';

IconData mapMaterialSymbol(String name) {
  return switch (name) {
    'home' => Icons.home_rounded,
    'mic' => Icons.mic_rounded,
    'analytics' => Icons.analytics_rounded,
    'menu_book' => Icons.menu_book_rounded,
    'graphic_eq' => Icons.graphic_eq_rounded,
    'local_cafe' => Icons.local_cafe_rounded,
    'work' => Icons.work_rounded,
    'flight_takeoff' => Icons.flight_takeoff_rounded,
    'groups' => Icons.groups_rounded,
    'restaurant' => Icons.restaurant_rounded,
    'lock' => Icons.lock_rounded,
    'lightbulb' => Icons.lightbulb_rounded,
    'timer' => Icons.timer_rounded,
    'speed' => Icons.speed_rounded,
    'psychology' => Icons.psychology_rounded,
    _ => Icons.circle_rounded,
  };
}
