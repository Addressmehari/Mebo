import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/habits/habit.dart';
import 'package:habo/helpers.dart';

/// Data for a single day in the week view
class WeekDayData {
  final DateTime date;
  final int completedHabits;
  final int totalHabits;
  final int failedHabits;
  final int skippedHabits;
  final bool isToday;

  WeekDayData({
    required this.date,
    required this.completedHabits,
    required this.totalHabits,
    this.failedHabits = 0,
    this.skippedHabits = 0,
    this.isToday = false,
  });

  /// Returns the completion status for this day
  DayStatus get status {
    if (completedHabits + skippedHabits >= totalHabits && totalHabits > 0) {
      return DayStatus.complete;
    } else if (completedHabits > 0 || skippedHabits > 0) {
      return DayStatus.partial;
    } else if (failedHabits > 0) {
      return DayStatus.failed;
    }
    return DayStatus.empty;
  }

  double get completionPercentage {
    if (totalHabits == 0) return 0;
    return (completedHabits + skippedHabits) / totalHabits;
  }
}

enum DayStatus { empty, partial, complete, failed }

/// Helper to calculate week data from habits
class WeekWidgetHelper {
  /// Get data for the current week (Monday to Sunday)
  static List<WeekDayData> getWeekData(List<Habit> habits) {
    final now = DateTime.now();
    final today = transformDate(now);
    
    // Find the start of the week (Monday)
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final monday = now.subtract(Duration(days: weekday - 1));
    
    List<WeekDayData> weekData = [];
    
    // Filter out archived habits
    final activeHabits = habits.where((h) => !h.habitData.archived).toList();
    
    for (int i = 0; i < 7; i++) {
      final date = transformDate(monday.add(Duration(days: i)));
      final isToday = date.year == today.year && 
                      date.month == today.month && 
                      date.day == today.day;
      
      int completed = 0;
      int failed = 0;
      int skipped = 0;
      
      for (var habit in activeHabits) {
        final event = habit.habitData.events[date];
        if (event != null && event.isNotEmpty) {
          final dayType = event[0] as DayType;
          if (dayType == DayType.check) {
            completed++;
          } else if (dayType == DayType.progress && habit.habitData.isNumeric) {
            if (event.length > 2) {
              final progressValue = (event[2] as num?)?.toDouble() ?? 0.0;
              if (progressValue >= habit.habitData.targetValue) {
                completed++;
              }
            }
          } else if (dayType == DayType.meter) {
            completed++;
          } else if (dayType == DayType.skip) {
            skipped++;
          } else if (dayType == DayType.fail) {
            failed++;
          }
        }
      }
      
      weekData.add(WeekDayData(
        date: date,
        completedHabits: completed,
        totalHabits: activeHabits.length,
        failedHabits: failed,
        skippedHabits: skipped,
        isToday: isToday,
      ));
    }
    
    return weekData;
  }

  /// Calculate the total completed days this week
  static int getCompletedDays(List<WeekDayData> weekData) {
    return weekData.where((d) => d.status == DayStatus.complete).length;
  }
}

/// A horizontal week view home widget (4x1 size, approximately 320x80)
class WeekViewWidget extends StatelessWidget {
  final List<WeekDayData> weekData;
  final Color? backgroundColor;
  final Color? primaryColor;
  final Color? textColor;

  const WeekViewWidget({
    super.key,
    required this.weekData,
    this.backgroundColor,
    this.primaryColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.transparent;
    final primColor = primaryColor ?? HaboColors.primary;
    final txtColor = textColor ?? Colors.black87;
    
    final completedDays = WeekWidgetHelper.getCompletedDays(weekData);
    
    return Container(
      width: 320,
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: txtColor,
                ),
              ),
              Text(
                '$completedDays/7 days',
                style: TextStyle(
                  fontSize: 12,
                  color: txtColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Week days row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekData.map((day) => _buildDayColumn(day, primColor, txtColor)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(WeekDayData day, Color primaryColor, Color textColor) {
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final dayName = dayNames[day.date.weekday - 1];
    
    Color circleColor;
    IconData? icon;
    
    switch (day.status) {
      case DayStatus.complete:
        circleColor = primaryColor;
        icon = Icons.check;
        break;
      case DayStatus.partial:
        circleColor = primaryColor.withValues(alpha: 0.4);
        icon = null;
        break;
      case DayStatus.failed:
        circleColor = Colors.red.withValues(alpha: 0.7);
        icon = Icons.close;
        break;
      case DayStatus.empty:
        circleColor = Colors.grey.withValues(alpha: 0.3);
        icon = null;
        break;
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Day name
        Text(
          dayName,
          style: TextStyle(
            fontSize: 11,
            fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
            color: day.isToday ? primaryColor : textColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        // Circle indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: day.isToday 
                ? Border.all(color: primaryColor, width: 2)
                : null,
            boxShadow: day.isToday
                ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 4)]
                : null,
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 18, color: Colors.white)
                : day.status == DayStatus.partial
                    ? Text(
                        '${((day.completionPercentage) * 100).round()}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
          ),
        ),
        const SizedBox(height: 2),
        // Date number
        Text(
          '${day.date.day}',
          style: TextStyle(
            fontSize: 10,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}


