import 'dart:collection';

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
  });

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

  // Helper methods for habit types
  bool get isNumeric => habitType == HabitType.numeric;
  bool get isBoolean => habitType == HabitType.boolean;
  bool get isDiary => habitType == HabitType.diary;
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

    if (event[0] == DayType.meter && event.length > 2) {
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
    } else {
      return getProgressForDate(date) >= targetValue;
    }
  }
}
