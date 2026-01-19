import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:habo/model/habo_model.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:habo/habits/habit.dart';
import 'package:habo/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

class CityGenerator {
  final HabitsManager habitsManager;

  CityGenerator(this.habitsManager);

  Future<void> generateAndSave() async {
    // 1. Calculate Total Houses needed (Total Ticks / 2)
    final allHabits = habitsManager.allHabits;
    final List<Map<String, dynamic>> housePopulation = [];

    for (var habit in allHabits) {
      // Calculate ticks
      int ticks = 0;
      habit.habitData.events.forEach((date, event) {
        if (event[0] == DayType.check) {
          ticks++;
        }
      });

      // For every 2 ticks, create a house entry
      int houseCount = (ticks / 2).floor();
      
      // Ensure at least one house if there is any progress? 
      // User said "for every 2 ticks", implies 0 ticks = 0 houses.
      // But let's show at least the main habit house if count is 0 but habit exists?
      // Strict interpretation:
      if (houseCount == 0 && ticks > 0) houseCount = 1; // Bonus for starting

      for (int i = 0; i < houseCount; i++) {
        housePopulation.add({
          'username': "${habit.habitData.title} ${i + 1}", // e.g. "Gym 1"
          'baseColor': _colorToHex(habit.habitData.categories.isNotEmpty 
              ? (habit.habitData.categories.first.color ?? HaboColors.primary)
              : HaboColors.primary),
          'habitName': habit.habitData.title,
          'joinedAt': DateTime.now().toIso8601String(), // Could be event date
        });
      }
    }
    
    // Always add a "City Hall" (User profile) at the center
    if (housePopulation.isEmpty) {
        housePopulation.add({
            'username': "Habo HQ",
            'baseColor': "#ffffff",
            'habitName': "System",
            'joinedAt': DateTime.now().toIso8601String(),
        });
    }

    // 2. Generate Coordinate Layout (Ported from Python)
    final layout = _generateCitySlots(housePopulation.length);
    final slots = layout.slots;
    final facings = layout.facings;
    final roads = layout.roads;

    // 3. Assign Population to Slots
    final List<Map<String, dynamic>> finalHouses = [];
    
    for (int i = 0; i < housePopulation.length; i++) {
        if (i >= slots.length) break;
        
        final p = housePopulation[i];
        final slot = slots[i];
        
        // Pseudo-random attributes based on name
        final attrs = _stringToPseudoRandom(p['username']);
        
        finalHouses.add({
            "x": slot.x,
            "y": slot.y,
            "color": p['baseColor'], // Use category color
            "roofStyle": attrs[0],
            "doorStyle": attrs[1],
            "windowStyle": attrs[2],
            "chimneyStyle": attrs[3],
            "wallStyle": attrs[4],
            "username": p['username'],
            "facing": facings[i],
            "has_terrace": i % 5 == 0, // Every 5th house gets a terrace
            "abandoned": false,
            "joined_at": p['joinedAt'],
            "last_seen": DateTime.now().toIso8601String()
        });
    }

    // 4. Save to Disk (Overwrite the local server file)
    final docDir = await getApplicationDocumentsDirectory();
    final gitvilleDir = Directory(p.join(docDir.path, 'gitville', 'data'));
    if (!await gitvilleDir.exists()) {
        await gitvilleDir.create(recursive: true);
    }

    final housesFile = File(p.join(gitvilleDir.path, 'stargazers_houses.json'));
    await housesFile.writeAsString(jsonEncode(finalHouses));

    final roadsFile = File(p.join(gitvilleDir.path, 'roads.json'));
    final roadsJson = roads.map((r) => {"x": r.x, "y": r.y}).toList();
    await roadsFile.writeAsString(jsonEncode(roadsJson));
    
    debugPrint("City Generated: ${finalHouses.length} houses.");
  }

  // --- Layout Algorithm (Ported from fetch_stargazers.py) ---
  
  _CityLayout _generateCitySlots(int limit) {
     List<Point<double>> slots = [];
     List<String> facings = [];
     
     // Center House
     slots.add(const Point(0.0, 0.0));
     facings.add("down");
     
     if (limit <= 1) return _CityLayout(slots, facings, []);

     const int CLUSTER_ROWS = 4;
     const int CLUSTER_COLS = 4;
     const int HOUSE_GAP = 2; // Reduced gap for tighter city
     const int STREET_GAP = 2;
     const int HOUSES_PER_BLOCK = CLUSTER_ROWS * CLUSTER_COLS;
     const double MAIN_AVENUE_WIDTH = 6.0;

     final int BLOCK_WIDTH = (CLUSTER_COLS - 1) * HOUSE_GAP;
     final int BLOCK_HEIGHT = (CLUSTER_ROWS - 1) * HOUSE_GAP;
     final int BLOCK_STRIDE_X = BLOCK_WIDTH + STREET_GAP;
     final int BLOCK_STRIDE_Y = BLOCK_HEIGHT + STREET_GAP;

     int totalBlocks = (limit / HOUSES_PER_BLOCK).ceil();
     
     final quadrants = [
         const Point(1, -1), const Point(-1, -1), 
         const Point(-1, 1), const Point(1, 1)
     ];

     List<Point<int>> abstractBlocks = [];
     int layer = 0;
     while (abstractBlocks.length * 4 < totalBlocks + 4) {
         for (int x = 0; x <= layer; x++) {
             int y = layer - x;
             abstractBlocks.add(Point(x, y));
         }
         layer++;
     }

     Set<Point<int>> roadTiles = {};
     int housesPlaced = 1; // Already placed center

     for (var b in abstractBlocks) {
         for (var q in quadrants) {
             if (housesPlaced >= limit) break;
             
             double qx = q.x.toDouble();
             double qy = q.y.toDouble();

             double baseX = (MAIN_AVENUE_WIDTH / 2) * qx;
             double baseY = (MAIN_AVENUE_WIDTH / 2) * qy;

             double blockStartX = baseX + (b.x * BLOCK_STRIDE_X * qx);
             double blockStartY = baseY + (b.y * BLOCK_STRIDE_Y * qy);

             for (int i = 0; i < HOUSES_PER_BLOCK; i++) {
                 if (slots.length >= limit) break;

                 int ix = i % CLUSTER_COLS;
                 int iy = (i / CLUSTER_COLS).floor();

                 double hx = blockStartX + (ix * HOUSE_GAP * qx);
                 double hy = blockStartY + (iy * HOUSE_GAP * qy);

                 slots.add(Point(hx, hy));
                 facings.add(hx > 0 ? "left" : "right");
                 housesPlaced++;
             }
             
             // Road Generation Logic
             int getRCoord(int idx) => (idx == 0) ? 0 : 2 + idx * 8;
             
             double rxIn = (getRCoord(b.x) * qx).toDouble();
             double rxOut = (getRCoord(b.x + 1) * qx).toDouble();
             double ryIn = (getRCoord(b.y) * qy).toDouble();
             double ryOut = (getRCoord(b.y + 1) * qy).toDouble();
             
             int sx = min(rxIn, rxOut).toInt();
             int ex = max(rxIn, rxOut).toInt();
             int sy = min(ryIn, ryOut).toInt();
             int ey = max(ryIn, ryOut).toInt();

             for (int x = sx; x <= ex; x++) {
                 roadTiles.add(Point(x, ryIn.toInt()));
                 roadTiles.add(Point(x, ryOut.toInt()));
             }
             for (int y = sy; y <= ey; y++) {
                 roadTiles.add(Point(rxIn.toInt(), y));
                 roadTiles.add(Point(rxOut.toInt(), y));
             }
         }
     }
     
     // Cleanup center roads
     for (int i = -2; i <= 2; i++) {
        roadTiles.remove(Point(0, i));
        roadTiles.remove(Point(i, 0));
     }
     // Add ring
     for (int x = -2; x<=2; x++) {
        roadTiles.add(Point(x, -2)); roadTiles.add(Point(x, 2));
     }
     for (int y = -2; y<=2; y++) {
        roadTiles.add(Point(-2, y)); roadTiles.add(Point(2, y));
     }

     return _CityLayout(slots, facings, roadTiles.toList());
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  List<int> _stringToPseudoRandom(String s) {
    var bytes = utf8.encode(s);
    var digest = md5.convert(bytes);
    var hex = digest.toString();
    
    List<int> nums = [];
    for (int i = 0; i < 5; i++) {
        int val = int.parse(hex[i], radix: 16);
        nums.add(val % 4);
    }
    return nums;
  }
}

class _CityLayout {
    final List<Point<double>> slots;
    final List<String> facings;
    final List<Point<int>> roads;
    _CityLayout(this.slots, this.facings, this.roads);
}
