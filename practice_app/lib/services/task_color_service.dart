import 'package:flutter/material.dart';
import 'dart:math';

class TaskColorService {
  static final TaskColorService _instance = TaskColorService._internal();
  factory TaskColorService() => _instance;
  TaskColorService._internal();

  final Map<String, Color> _taskColors = {};
  final Random _random = Random();

  Color getColorForTask(String title) {
    if (_taskColors.containsKey(title)) {
      return _taskColors[title]!;
    }

    // Generate a more varied color
    var hue = _random.nextDouble() * 360; // Full hue range
    var saturation = 0.5 + _random.nextDouble() * 0.3; // 50-80% saturation
    var lightness = 0.4 + _random.nextDouble() * 0.3; // 40-70% lightness

    // Ensure minimum contrast between colors
    final existingColors = _taskColors.values.toList();
    Color color;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      color = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
      attempts++;

      // If we've tried too many times, just use the last generated color
      if (attempts >= maxAttempts) break;

      // Check if this color is too similar to existing colors
      bool isTooSimilar = existingColors.any((existingColor) {
        final existingHSL = HSLColor.fromColor(existingColor);
        final newHSL = HSLColor.fromColor(color);

        // Check hue difference (considering color wheel)
        final hueDiff = (existingHSL.hue - newHSL.hue).abs();
        final minHueDiff = 30.0; // Minimum 30 degrees difference

        // Check saturation and lightness differences
        final satDiff = (existingHSL.saturation - newHSL.saturation).abs();
        final lightDiff = (existingHSL.lightness - newHSL.lightness).abs();
        final minSatDiff = 0.2; // Minimum 20% saturation difference
        final minLightDiff = 0.2; // Minimum 20% lightness difference

        return hueDiff < minHueDiff &&
            satDiff < minSatDiff &&
            lightDiff < minLightDiff;
      });

      if (!isTooSimilar) break;

      // Try again with different values
      hue = _random.nextDouble() * 360;
      saturation = 0.5 + _random.nextDouble() * 0.3;
      lightness = 0.4 + _random.nextDouble() * 0.3;
    } while (true);

    _taskColors[title] = color;
    return color;
  }
}
