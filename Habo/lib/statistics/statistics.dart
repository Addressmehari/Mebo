import 'dart:collection';

import 'package:habo/constants.dart';
import 'package:habo/habits/habit.dart';

class StatisticsData {
  String title = '';
  int topStreak = 0;
  int actualStreak = 0;
  int checks = 0;
  int skips = 0;
  int fails = 0;
  int progress = 0;
  int meter = 0; // Add meter as separate category
  int savings = 0; // Add savings as separate category
  double totalValue = 0; // Track amount saved
  SplayTreeMap<int, Map<DayType, List<int>>> monthlyCheck = SplayTreeMap();
  
  // New fields for enhanced visualization
  HabitType habitType = HabitType.boolean;
  String unit = '';
  double targetValue = 0;
  Map<DateTime, double> valueHistory = {};
}

class OverallStatisticsData {
  int checks = 0;
  int skips = 0;
  int fails = 0;
  int progress = 0;
  int meter = 0; 
  int savings = 0; // Separate category for savings
  double totalValue = 0; // Total amount saved
}

class AllStatistics {
  OverallStatisticsData total = OverallStatisticsData();
  List<StatisticsData> habitsData = [];
}

class Statistics {
  static Future<AllStatistics> calculateStatistics(List<Habit>? habits) async {
    AllStatistics stats = AllStatistics();

    if (habits == null) return stats;

  for (var habit in habits) {
      var stat = StatisticsData();
      stat.title = habit.habitData.title;
      stat.habitType = habit.habitData.habitType;
      stat.unit = habit.habitData.unit;
      stat.targetValue = habit.habitData.targetValue;

      bool usingTwoDayRule = false;

      DateTime? lastDay;

      habit.habitData.events.forEach(
        (key, value) {
          if (value[0] != null && value[0] != DayType.clear) {
            if (lastDay != null && key.difference(lastDay!).inDays > 1) {
              stat.actualStreak = 0;
            }

            switch (value[0]) {
              case DayType.check:
                stat.checks++;
                stat.actualStreak++;
                if (stat.actualStreak > stat.topStreak) {
                  stat.topStreak = stat.actualStreak;
                }
                usingTwoDayRule = false;
                break;
              case DayType.progress:
                // Handle numeric habit progress events as separate category
                stat.progress++;
                if (habit.habitData.isNumeric && value.length > 2) {
                  final progressValue = (value[2] as num?)?.toDouble() ?? 0.0;
                  stat.valueHistory[key] = progressValue;
                  
                  if (progressValue >= habit.habitData.targetValue) {
                    // 100% or more = maintain streak
                    stat.actualStreak++;
                    if (stat.actualStreak > stat.topStreak) {
                      stat.topStreak = stat.actualStreak;
                    }
                    usingTwoDayRule = false;
                  }
                } else {
                  // Fallback for non-numeric progress events
                  if (usingTwoDayRule) {
                    stat.actualStreak = 0;
                  }
                }
                usingTwoDayRule = false;
                break;
              case DayType.skip:
                stat.skips++;
                if (usingTwoDayRule) {
                  stat.actualStreak = 0;
                }
                break;
              case DayType.fail:
                stat.fails++;
                if (habit.habitData.twoDayRule) {
                  if (usingTwoDayRule) {
                    stat.actualStreak = 0;
                  } else {
                    usingTwoDayRule = true;
                  }
                } else {
                  stat.actualStreak = 0;
                }
                break;
              case DayType.meter:
                stat.meter++;
                 if (value.length > 2) {
                   stat.valueHistory[key] = (value[2] as num?)?.toDouble() ?? 0.0;
                 }
                // Meter entries always maintain streak
                stat.actualStreak++;
                if (stat.actualStreak > stat.topStreak) {
                  stat.topStreak = stat.actualStreak;
                }
                usingTwoDayRule = false;
                break;
              case DayType.savings:
                stat.savings++;
                if (value.length > 2) {
                  double val = (value[2] as num?)?.toDouble() ?? 0.0;
                  stat.totalValue += val;
                  stat.valueHistory[key] = val;
                }
                // Savings maintain streak
                stat.actualStreak++;
                if (stat.actualStreak > stat.topStreak) {
                  stat.topStreak = stat.actualStreak;
                }
                usingTwoDayRule = false;
                break;
            }

            generateYearIfNull(stat, key.year);

            if (value[0] != DayType.clear) {
              // Track only known event types in monthly stats
              final yearData = stat.monthlyCheck[key.year];
              if (yearData != null && yearData.containsKey(value[0])) {
                yearData[value[0]]![key.month - 1]++;
              }
            }

            lastDay = key;
          }
        },
      );

      generateYearIfNull(stat, DateTime.now().year);
      stats.habitsData.add(stat);
      stats.total.checks += stat.checks;
      stats.total.fails += stat.fails;
      stats.total.skips += stat.skips;
      stats.total.progress += stat.progress;
      stats.total.meter += stat.meter;
      stats.total.savings += stat.savings;
      stats.total.totalValue += stat.totalValue; // Total savings
    }
    return stats;
  }

  static void generateYearIfNull(StatisticsData stat, int year) {
    if (stat.monthlyCheck[year] == null) {
      stat.monthlyCheck[year] = {
        DayType.check: List.filled(12, 0),
        DayType.skip: List.filled(12, 0),
        DayType.fail: List.filled(12, 0),
        DayType.progress: List.filled(12, 0),
        DayType.meter: List.filled(12, 0),
        DayType.savings: List.filled(12, 0), // Add savings tracking
      };
    }
  }
}
