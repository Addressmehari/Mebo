import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:habo/habits/habit.dart';
import 'package:habo/model/habo_model.dart';
import 'package:habo/helpers.dart';
import 'package:habo/notifications.dart' as notifications;

/// Handles notification action button presses and inline replies.
class NotificationActionHandler {
  static HabitsManager? _habitsManager;
  static final List<ReceivedAction> _actionQueue = [];

  /// Must be called once during app initialization.
  static void initialize(HabitsManager habitsManager) {
    _habitsManager = habitsManager;
    debugPrint('[NotificationAction] Handler initialized with HabitsManager');
    
    if (_actionQueue.isNotEmpty) {
      debugPrint('[NotificationAction] Processing ${_actionQueue.length} queued actions');
      final actions = List<ReceivedAction>.from(_actionQueue);
      _actionQueue.clear();
      for (var action in actions) {
        onActionReceived(action);
      }
    }
  }

  /// Register the awesome_notifications action listeners.
  static Future<void> setupListeners() async {
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
    debugPrint('[NotificationAction] Listeners registered successfully');

    ReceivedAction? initialAction = await AwesomeNotifications().getInitialNotificationAction();
    if (initialAction != null) {
      debugPrint('[NotificationAction] Initial action detected: ${initialAction.buttonKeyPressed}');
      onActionReceived(initialAction);
    }
  }

  /// Called when user taps on a notification or presses an action button.
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    final String buttonKey = receivedAction.buttonKeyPressed;
    final int? rawNotificationId = receivedAction.id;
    
    // Fallback: try to get habit ID from payload if it exists
    final String? payloadHabitId = receivedAction.payload?['habitId'];
    final int? habitIdToResolve = (payloadHabitId != null) ? int.tryParse(payloadHabitId) : rawNotificationId;

    if (habitIdToResolve == null) {
      debugPrint('[NotificationAction] Error: No habit ID found in notification action');
      return;
    }

    final int actualHabitId = _resolveHabitId(habitIdToResolve);
    final String inputText = receivedAction.buttonKeyInput;

    final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final DateTime normalizedDate = transformDate(today);

    debugPrint('[NotificationAction] Handle: habit=$actualHabitId, button=$buttonKey');

    // ───── Background Isolate Handling ─────
    if (_habitsManager == null) {
      await _handleInBackground(actualHabitId, buttonKey, inputText, normalizedDate);
      return;
    }

    // ───── Foreground Handling ─────
    switch (buttonKey) {
      case 'DONE':
        _habitsManager!.completeHabitFromNotification(actualHabitId, today, [DayType.check, '']);
        break;

      case 'SKIP':
        _habitsManager!.completeHabitFromNotification(actualHabitId, today, [DayType.skip, '']);
        break;

      case 'METER_LOW':
        final value = _getMeterValue(actualHabitId, 'low');
        _habitsManager!.completeHabitFromNotification(actualHabitId, today, [DayType.meter, '', value]);
        break;

      case 'METER_MID':
        final value = _getMeterValue(actualHabitId, 'mid');
        _habitsManager!.completeHabitFromNotification(actualHabitId, today, [DayType.meter, '', value]);
        break;

      case 'METER_HIGH':
        final value = _getMeterValue(actualHabitId, 'high');
        _habitsManager!.completeHabitFromNotification(actualHabitId, today, [DayType.meter, '', value]);
        break;

      case 'DIARY_REPLY':
        if (inputText.trim().isNotEmpty) {
          final habit = _habitsManager!.findHabitById(actualHabitId);
          final event = _buildDiaryEvent(habit, inputText);
          _habitsManager!.completeHabitFromNotification(actualHabitId, today, event);
        }
        break;
    }
  }

  static Future<void> _handleInBackground(int habitId, String buttonKey, String inputText, DateTime date) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await notifications.initializeNotifications();
      
      final haboModel = HaboModel();
      await haboModel.initDatabase();
      
      final habit = await haboModel.getHabitById(habitId);
      if (habit == null) return;

      List? event;
      String? msg;

      switch (buttonKey) {
        case 'DONE':
          event = [DayType.check, ''];
          msg = 'Habit "${habit.habitData.title}" check marked! ✓';
          break;
        case 'SKIP':
          event = [DayType.skip, ''];
          msg = 'Habit "${habit.habitData.title}" skipped ⏭';
          break;
        case 'METER_LOW':
          final v = _calculateMeterValue(habit, 'low');
          event = [DayType.meter, '', v];
          msg = 'Logged ${v.toStringAsFixed(1)} for "${habit.habitData.title}"';
          break;
        case 'METER_MID':
          final v = _calculateMeterValue(habit, 'mid');
          event = [DayType.meter, '', v];
          msg = 'Logged ${v.toStringAsFixed(1)} for "${habit.habitData.title}"';
          break;
        case 'METER_HIGH':
          final v = _calculateMeterValue(habit, 'high');
          event = [DayType.meter, '', v];
          msg = 'Logged ${v.toStringAsFixed(1)} for "${habit.habitData.title}"';
          break;
        case 'DIARY_REPLY':
          if (inputText.trim().isNotEmpty) {
            event = _buildDiaryEvent(habit, inputText);
            msg = 'Diary saved for "${habit.habitData.title}" ✍️';
          }
          break;
      }

      if (event != null) {
        await haboModel.insertEvent(habitId, date, event);
        if (event[0] == DayType.check) {
          await notifications.rescheduleNotificationForTomorrow(habitId);
        }
        
        // Final confirmation notification
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 999000 + habitId,
            channelKey: 'app_notifications_habo',
            title: 'Habo: Action Recorded',
            body: msg ?? 'Success',
            summary: habit.habitData.title,
            category: NotificationCategory.Status,
          ),
        );
      }
    } catch (e) {
      debugPrint('[Background] Fail: $e');
    }
  }

  static List _buildDiaryEvent(Habit? habit, String text) {
    if (habit != null && habit.habitData.questions.isNotEmpty) {
      final firstQuestion = habit.habitData.questions.first;
      final diaryData = jsonEncode({firstQuestion: text.trim()});
      return [DayType.check, diaryData];
    }
    return [DayType.check, text.trim()];
  }

  static int _resolveHabitId(int notificationId) {
    return (notificationId >= 100000) ? (notificationId % 100000) : notificationId;
  }

  static double _getMeterValue(int habitId, String level) {
    final habit = _habitsManager?.findHabitById(habitId);
    if (habit == null) return 5.0;
    return _calculateMeterValue(habit, level);
  }

  static double _calculateMeterValue(Habit habit, String level) {
    final double min = habit.habitData.meterMin;
    final double max = habit.habitData.meterMax;
    final range = max - min;
    switch (level) {
      case 'low': return min + range * 0.25;
      case 'mid': return min + range * 0.5;
      case 'high': return min + range * 0.75;
      default: return min + range * 0.5;
    }
  }
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  await NotificationActionHandler.onActionReceived(receivedAction);
}

@pragma('vm:entry-point')
Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {}

@pragma('vm:entry-point')
Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {}

@pragma('vm:entry-point')
Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {}
