import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/habits/habits_manager.dart';

/// Handles notification action button presses and inline replies.
///
/// This service processes the user's interaction with heads-up notifications:
/// - Boolean habits: "Done" / "Skip" buttons
/// - Meter habits: Preset value buttons (Low / Mid / High)
/// - Diary habits: Inline text reply (WhatsApp-style)
class NotificationActionHandler {
  static HabitsManager? _habitsManager;

  /// Must be called once during app initialization so the handler
  /// can write events back to the habit manager.
  static void initialize(HabitsManager habitsManager) {
    _habitsManager = habitsManager;
  }

  /// Register the awesome_notifications action listeners.
  /// Call this once in main before runApp.
  static void setupListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
      onNotificationCreatedMethod: onNotificationCreated,
      onNotificationDisplayedMethod: onNotificationDisplayed,
      onDismissActionReceivedMethod: onDismissActionReceived,
    );
  }

  /// Called when user taps on a notification or presses an action button.
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    final String buttonKey = receivedAction.buttonKeyPressed;
    final int? habitId = receivedAction.id;
    final String? payload = receivedAction.payload?['habitType'];
    final String inputText = receivedAction.buttonKeyInput;

    if (habitId == null || _habitsManager == null) {
      debugPrint(
          '[NotificationAction] Skipped: habitId=$habitId, '
          'manager=${_habitsManager != null ? "ok" : "null"}');
      return;
    }

    // Resolve the actual habit ID (secondary notification IDs are offset by 100000*index)
    final int actualHabitId = _resolveHabitId(habitId);

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    debugPrint(
        '[NotificationAction] buttonKey=$buttonKey, habitId=$actualHabitId, '
        'payload=$payload, inputText=$inputText');

    switch (buttonKey) {
      // ── Boolean habit actions ──
      case 'DONE':
        _habitsManager!.completeHabitFromNotification(
            actualHabitId, today, [DayType.check, '']);
        break;

      case 'SKIP':
        _habitsManager!.completeHabitFromNotification(
            actualHabitId, today, [DayType.skip, '']);
        break;

      // ── Meter habit actions ──
      case 'METER_LOW':
        final double value = _getMeterValue(actualHabitId, 'low');
        _habitsManager!.completeHabitFromNotification(
            actualHabitId, today, [DayType.meter, '', value]);
        break;

      case 'METER_MID':
        final double value = _getMeterValue(actualHabitId, 'mid');
        _habitsManager!.completeHabitFromNotification(
            actualHabitId, today, [DayType.meter, '', value]);
        break;

      case 'METER_HIGH':
        final double value = _getMeterValue(actualHabitId, 'high');
        _habitsManager!.completeHabitFromNotification(
            actualHabitId, today, [DayType.meter, '', value]);
        break;

      // ── Diary habit actions (inline reply) ──
      case 'DIARY_REPLY':
        if (inputText.trim().isNotEmpty) {
          // Get the habit's first question to use as key
          final habit = _habitsManager!.findHabitById(actualHabitId);
          if (habit != null && habit.habitData.questions.isNotEmpty) {
            final firstQuestion = habit.habitData.questions.first;
            final diaryData = jsonEncode({firstQuestion: inputText.trim()});
            _habitsManager!.completeHabitFromNotification(
                actualHabitId, today, [DayType.check, diaryData]);
          } else {
            // Fallback – store as plain text
            _habitsManager!.completeHabitFromNotification(
                actualHabitId, today, [DayType.check, inputText.trim()]);
          }
        }
        break;

      default:
        // User tapped the notification body itself (no specific button)
        // Just open the app – no further action needed
        break;
    }
  }

  /// Resolves the original habit ID from a notification ID.
  /// Secondary reminders have IDs like habitId + (index * 100000).
  static int _resolveHabitId(int notificationId) {
    if (notificationId >= 100000) {
      return notificationId % 100000;
    }
    return notificationId;
  }

  /// Calculate meter value for Low / Mid / High presets.
  static double _getMeterValue(int habitId, String level) {
    final habit = _habitsManager?.findHabitById(habitId);
    double min = 0;
    double max = 10;
    if (habit != null) {
      min = habit.habitData.meterMin;
      max = habit.habitData.meterMax;
    }
    final range = max - min;
    switch (level) {
      case 'low':
        return min + range * 0.25;
      case 'mid':
        return min + range * 0.5;
      case 'high':
        return min + range * 0.75;
      default:
        return min + range * 0.5;
    }
  }

  // ── Required listener stubs ──

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreated(
      ReceivedNotification receivedNotification) async {}

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayed(
      ReceivedNotification receivedNotification) async {}

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceived(
      ReceivedAction receivedAction) async {}
}
