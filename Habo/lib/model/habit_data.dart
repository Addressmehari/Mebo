import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/model/category.dart';

class HabitData {
  HabitData({
    this.id,
    required this.position,
    required this.title,
    required this.twoDayRule,
    required this.cue,
    required this.routine,
    required this.reward,
    required this.showReward,
    required this.advanced,
    required this.notification,
    required this.notTime,
    required this.events,
    required this.sanction,
    required this.showSanction,
    required this.accountant,
    this.habitType = HabitType.boolean,
    this.targetValue = 100.0,
    this.partialValue = 10.0,
    this.unit = '',
    this.categories = const [],
    this.questions = const [],
    this.meterMin = 0.0,
    this.meterMax = 10.0,
    this.meterLabels = const [],
    this.archived = false,
    this.is24Hour = false,
    this.description = '',
    this.color = 0,
    this.reminders = const [],
    this.isSecret = false,
    this.overlayReminder = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Backwards compatibility for single notification time
  // If reminders list is empty, use notTime if notification is enabled
  List<TimeOfDay> get allReminders {
    if (reminders.isNotEmpty) return reminders;
    if (notification) return [notTime];
    return [];
  }

  SplayTreeMap<DateTime, List> events;
  int streak = 0;
  int? id;
  int position;
  String title;
  bool twoDayRule;
  String cue;
  String routine;
  String reward;
  bool showReward;
  bool advanced;
  bool notification;
  TimeOfDay notTime;
  String sanction;
  bool showSanction;
  String accountant;

  // Numeric habit fields
  HabitType habitType;
  double targetValue;
  double partialValue;
  String unit;

  // Categories assigned to this habit
  List<Category> categories;

  // Diary questions
  List<String> questions;

  // Meter habit fields
  double meterMin;
  double meterMax;
  List<String> meterLabels; // Optional labels for meter positions

  // Archive status
  bool archived;

  // 24-hour temporary task
  bool is24Hour;
  
  // Secret habit (requires auth to view)
  bool isSecret;
  
  DateTime createdAt;
  String description; // Description for 24-hour tasks

  // List of notification times
  List<TimeOfDay> reminders;

  // Custom color for the habit (0 = default theme color)
  int color;

  // New feature: overlay reminder toggle
  bool overlayReminder;

  // Helper methods for habit types
  bool get isNumeric => habitType == HabitType.numeric;
  bool get isBoolean => habitType == HabitType.boolean;
  bool get isDiary => habitType == HabitType.diary;
  bool get isSavings => habitType == HabitType.savings;
  bool get isMeter => habitType == HabitType.meter;

  double getProgressForDate(DateTime date) {
    final event = events[date];
    if (event == null) return 0.0;

    if (event[0] == DayType.check) return targetValue;
    if (event[0] == DayType.progress && event.length > 2) {
      return (event[2] as double?) ?? 0.0;
    }
    return 0.0;
  }

  double getMeterValueForDate(DateTime date) {
    final event = events[date];
    if (event == null) return meterMin;

    if ((event[0] == DayType.meter || event[0] == DayType.savings) &&
        event.length > 2) {
      return (event[2] as double?) ?? meterMin;
    }
    return meterMin;
  }

  double getProgressPercentage(DateTime date) {
    if (!isNumeric || targetValue <= 0) return 0.0;
    final progress = getProgressForDate(date);
    return (progress / targetValue).clamp(0.0, 1.0);
  }

  double getMeterPercentage(DateTime date) {
    if (!isMeter || meterMax <= meterMin) return 0.0;
    final value = getMeterValueForDate(date);
    return ((value - meterMin) / (meterMax - meterMin)).clamp(0.0, 1.0);
  }

  bool isCompletedForDate(DateTime date) {
    if (isBoolean) {
      final event = events[date];
      return event != null && event[0] == DayType.check;
    } else if (isMeter) {
      final event = events[date];
      return event != null && event[0] == DayType.meter;
    } else if (isSavings) {
      final event = events[date];
      return event != null &&
          event[0] == DayType.savings &&
          (event[2] as double? ?? 0.0) > 0;
    } else {
      return getProgressForDate(date) >= targetValue;
    }
  }

  // Get diary fill percentage (0.0 to 1.0) based on how many questions are answered
  double getDiaryFillPercentage(DateTime date) {
    if (!isDiary || questions.isEmpty) return 0.0;
    
    final event = events[date];
    if (event == null || event.length < 2 || event[1] == null || event[1] == '') {
      return 0.0;
    }
    
    try {
      // Try to parse the diary data as JSON
      final data = event[1] as String;
      final decoded = jsonDecode(data);
      
      if (decoded is Map<String, dynamic>) {
        // Count how many questions have non-empty answers
        int filledCount = 0;
        for (var question in questions) {
          final answer = decoded[question];
          if (answer != null && answer.toString().trim().isNotEmpty) {
            filledCount++;
          }
        }
        return filledCount / questions.length;
      }
    } catch (e) {
      // If JSON parsing fails, assume it's old plain text format
      // In that case, if there's any text, consider it as partially filled (0.5)
      return 0.5;
    }
    
    return 0.0;
  }

  // Get the number of filled questions in a diary entry
  int getDiaryFilledCount(DateTime date) {
    if (!isDiary || questions.isEmpty) return 0;
    
    final event = events[date];
    if (event == null || event.length < 2 || event[1] == null || event[1] == '') {
      return 0;
    }
    
    try {
      final data = event[1] as String;
      final decoded = jsonDecode(data);
      
      if (decoded is Map<String, dynamic>) {
        int filledCount = 0;
        for (var question in questions) {
          final answer = decoded[question];
          if (answer != null && answer.toString().trim().isNotEmpty) {
            filledCount++;
          }
        }
        return filledCount;
      }
    } catch (e) {
      // Fallback for old format
      return 1;
    }
    
    return 0;
  }
}
