import 'package:flutter/material.dart';
import 'dart:math';

class TagColorService {
  static final TagColorService _instance = TagColorService._internal();
  factory TagColorService() => _instance;
  TagColorService._internal();

  final Map<String, Color> _tagColors = {};
  final Random _random = Random();

  Color getColorForTag(String tag) {
    if (!_tagColors.containsKey(tag)) {
      _tagColors[tag] = _generateRandomColor();
    }
    return _tagColors[tag]!;
  }

  Color _generateRandomColor() {
    // Generate pastel colors that are easy on the eyes
    final hue = _random.nextDouble() * 360;
    return HSLColor.fromAHSL(1, hue, 0.7, 0.8).toColor();
  }

  void clearColors() {
    _tagColors.clear();
  }
}
