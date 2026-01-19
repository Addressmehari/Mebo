import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart'; // For HSVColor
import 'package:habo/constants.dart';
import 'package:habo/habits/habit.dart';
import 'package:habo/model/habit_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CityGenerator {
  /// Generates the city data based on the provided list of habits
  /// and writes it to the local server directory, overwriting the default data.
  static Future<void> generateAndSave(List<Habit> habits) async {
    final cityData = _generateCityData(habits);
    final jsonString = jsonEncode(cityData);

    final docDir = await getApplicationDocumentsDirectory();
    final dataFile = File(p.join(docDir.path, 'gitville', 'data', 'stargazers_houses.json'));

    // Ensure directory exists (it should if server started, but good to be safe)
    if (!await dataFile.parent.exists()) {
      await dataFile.parent.create(recursive: true);
    }

    await dataFile.writeAsString(jsonString);
  }

  static List<Map<String, dynamic>> _generateCityData(List<Habit> habits) {
    if (habits.isEmpty) return [];

    // 1. Collect all unique dates from all habits
    final Set<DateTime> uniqueDates = {};
    for (var habit in habits) {
      uniqueDates.addAll(habit.habitData.events.keys);
    }
    
    // Sort dates from OLDEST to NEWEST (Chronological)
    // This ensures that Index 0 is always the first day used, Index 1 is the next, etc.
    // So old dates stick to their original slots as list grows.
    final sortedDates = uniqueDates.toList()..sort();
    
    // Reserve Center (0,0) for the "User" representation
    // We will generate a special "Owner" house at slot 0.
    // The actual dates will fill slots 1..N.
    
    // 2. Generate Grid Slots
    // Limit = dates + 1 (for owner)
    final layout = _generateCitySlots(sortedDates.length + 1);
    final slots = layout['slots'] as List<Point>;
    final facings = layout['facings'] as List<String>;
    
    List<Map<String, dynamic>> cityHouses = [];

    // Add Owner House at Slot 0
    if (slots.isNotEmpty) {
        cityHouses.add(_generateOwnerHouse(slots[0], facings[0]));
    }

    // Add Date Houses starting at Slot 1
    for (int i = 0; i < sortedDates.length; i++) {
        // Offset by 1 because slot 0 is taken
        int slotIndex = i + 1;
        if (slotIndex >= slots.length) break;
        
        final date = sortedDates[i];
        final slot = slots[slotIndex];
        final facing = facings[slotIndex];
        
        cityHouses.add(_mapDateToHouse(date, habits, slot.x, slot.y, facing));
    }

    return cityHouses;
  }

  static Map<String, dynamic> _generateOwnerHouse(Point slot, String facing) {
      return {
      "x": slot.x,
      "y": slot.y,
      "color": "#FFC107", // Gold color for the User/Center
      "roofStyle": 0,
      "doorStyle": 0,
      "windowStyle": 0,
      "chimneyStyle": 1, 
      "wallStyle": 0,
      "username": "You", // Label
      "facing": facing,
      "has_terrace": true, // Owner always has terrace
      "abandoned": false,
      "joined_at": DateTime.now().toIso8601String(),
      "last_seen": DateTime.now().toIso8601String()
    };
  }

  static Map<String, dynamic> _generateCitySlots(int limit) {
    List<Point> slots = [];
    List<String> facingDir = [];
    
    // 0. Central House
    slots.add(Point(0, 0));
    facingDir.add("down");
    
    if (limit <= 1) {
      return {'slots': slots, 'facings': facingDir};
    }

    const int houseGap = 2;
    // const int streetGap = 2; // Unused in simplistic slot calc but used in block stride
    const int mainAvenueWidth = 6;
    const int clusterRows = 4;
    const int clusterCols = 4;
    const int housesPerBlock = clusterRows * clusterCols;
    
    const int blockWidth = (clusterCols - 1) * houseGap;
    const int blockHeight = (clusterRows - 1) * houseGap;
    
    const int blockStrideX = blockWidth + 2; // + STREET_GAP
    const int blockStrideY = blockHeight + 2;
    
    final int totalBlocks = (limit / housesPerBlock).ceil();
    
    // Quadrants: Top-Right, Top-Left, Bottom-Left, Bottom-Right (Cartesian)
    // Python code uses: (1, -1), (-1, -1), (-1, 1), (1, 1) -> Note Y axis direction in ISO might vary
    final quadrants = [
      const Point(1, -1), 
      const Point(-1, -1), 
      const Point(-1, 1), 
      const Point(1, 1)
    ];
    
    List<Point> abstractBlockPositions = [];
    int layer = 0;
    while (abstractBlockPositions.length * 4 < totalBlocks + 4) {
      for (int x = 0; x <= layer; x++) {
        int y = layer - x;
        abstractBlockPositions.add(Point(x, y));
      }
      layer++;
    }
    
    int housesPlaced = 1; // 0,0 is already placed
    
    for (var b in abstractBlockPositions) {
      for (int qIdx = 0; qIdx < 4; qIdx++) {
        if (housesPlaced >= limit) break;
        
        final q = quadrants[qIdx];
        final qx = q.x;
        final qy = q.y;
        
        final double baseX = (mainAvenueWidth / 2) * qx;
        final double baseY = (mainAvenueWidth / 2) * qy;
        
        final double blockStartX = baseX + (b.x * blockStrideX * qx);
        final double blockStartY = baseY + (b.y * blockStrideY * qy);
        
        for (int i = 0; i < housesPerBlock; i++) {
          if (housesPlaced >= limit) break;
          
          int ix = i % clusterCols;
          int iy = i ~/ clusterCols;
          
          final double houseX = blockStartX + (ix * houseGap * qx);
          final double houseY = blockStartY + (iy * houseGap * qy);
          
          slots.add(Point(houseX.toInt(), houseY.toInt()));
          
          if (houseX > 0) {
            facingDir.add("left");
          } else {
            facingDir.add("right");
          }
          
          housesPlaced++;
        }
      }
    }
    
    return {'slots': slots, 'facings': facingDir};
  }

  static Map<String, dynamic> _mapDateToHouse(DateTime date, List<Habit> habits, int x, int y, String facing) {
    bool anyFail = false;
    int checkCount = 0;
    bool hasDiaryEntry = false;
    
    // Check all habits for this specific date
    for (var habit in habits) {
        final event = habit.habitData.events[date];
        if (event != null) {
            final dayType = event[0] as DayType;
            if (dayType == DayType.fail) {
                anyFail = true;
            } else if (dayType == DayType.check) {
                checkCount++;
                // Check if this is a diary habit that was filled
                if (habit.habitData.isDiary) {
                    hasDiaryEntry = true;
                }
            }
        }
    }

    // Formatting date for label
    final label = "${date.day}/${date.month}";
    
    // Generate Attributes based on Date Seed
    final seed = "${date.year}-${date.month}-${date.day}";
    final attrs = _generateAttributes(seed);

    // House gets terrace if: 3+ habits checked OR any diary habit was filled
    final hasTerrace = checkCount > 3 || hasDiaryEntry;

    return {
      "x": x,
      "y": y,
      "color": attrs['color'],
      "roofStyle": attrs['roofStyle'],
      "doorStyle": attrs['doorStyle'],
      "windowStyle": attrs['windowStyle'],
      "chimneyStyle": attrs['chimneyStyle'],
      "wallStyle": attrs['wallStyle'],
      "username": label,
      "facing": facing,
      "has_terrace": hasTerrace,
      "abandoned": anyFail,
      "joined_at": date.toIso8601String(),
      "last_seen": DateTime.now().toIso8601String()
    };
  }

  static Map<String, dynamic> _generateAttributes(String seed) {
    // Use the string hash code to seed the random generator for consistency
    final rng = Random(seed.hashCode);
    
    // Generates a nice bright color (avoiding too dark/black)
    // Hue: 0-360, Saturation: 60-100, Lightness: 50-70
    // Simple approach: HSV to Color
    // Random Hue
    double h = rng.nextDouble() * 360;
    // High Saturation
    double s = 0.6 + (rng.nextDouble() * 0.4); 
    // Medium-High Value
    double v = 0.6 + (rng.nextDouble() * 0.3);

    final color = HSVColor.fromAHSV(1.0, h, s, v).toColor();
    final colorHex = '#${color.value.toRadixString(16).substring(2)}';

    return {
      'color': colorHex,
      'roofStyle': rng.nextInt(3),   // 0-2
      'doorStyle': rng.nextInt(3),   // 0-2
      'windowStyle': rng.nextInt(3), // 0-2
      'chimneyStyle': rng.nextInt(3),// 0-2
      'wallStyle': rng.nextInt(3),   // 0-2
    };
  }
}

class Point {
  final int x;
  final int y;
  const Point(this.x, this.y);
}
