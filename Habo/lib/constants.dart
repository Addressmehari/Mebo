import 'package:flutter/material.dart';

enum Themes { device, light, dark, oled, materialYou }

enum HabitType { boolean, numeric, diary, meter, savings }

enum DayType { clear, check, fail, skip, progress, meter, savings }

class HaboColors {
  static const Color primary = Color(0xFF09BF30);
  static const Color red = Color(0xFFF44336);
  static const Color skip = Color(0xFFFBC02D);
  static const Color orange = Color(0xFFFF9800);
  static const Color progress = Color(0xFF2196F3);
  static const Color progressBackground = Color(0xFFE3F2FD);

  // Custom habit colors (Pastel/Light)
  // Index 0 is reserved for "Default" (Theme color)
  static const List<Color> habitPalette = [
    Colors.transparent, // 0: Default
    Color(0xFFE57373), // 1: Red 300
    Color(0xFFFFB74D), // 2: Orange 300
    Color(0xFFFFF176), // 3: Yellow 300
    Color(0xFF81C784), // 4: Green 300
    Color(0xFF64B5F6), // 5: Blue 300
    Color(0xFFBA68C8), // 6: Purple 300
  ];
  
  static Color getHabitColor(int index, Color defaultColor) {
    if (index <= 0 || index >= habitPalette.length) {
      return defaultColor;
    }
    return habitPalette[index];
  }
}
