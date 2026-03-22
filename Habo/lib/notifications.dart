import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/generated/l10n.dart';
import 'package:habo/services/notification_messages.dart';

bool platformSupportsNotifications() => Platform.isAndroid || Platform.isIOS;

Future<void> initializeNotifications() async {
  await AwesomeNotifications().initialize(
    'resource://raw/res_app_icon',
    [
      NotificationChannel(
          channelKey: 'app_notifications_habo',
          channelName: 'App notifications',
          channelDescription:
              'Notification channel for application notifications',
          defaultColor: HaboColors.primary,
          importance: NotificationImportance.Max,
          criticalAlerts: true),
      NotificationChannel(
          channelKey: 'habit_notifications_habo',
          channelName: 'Habit notifications',
          channelDescription: 'Notification channel for habit notifications',
          defaultColor: HaboColors.primary,
          importance: NotificationImportance.Max,
          criticalAlerts: true),
      NotificationChannel(
          channelKey: 'smart_notifications_habo',
          channelName: 'Smart habit reminders',
          channelDescription: 'Personalized motivational reminders',
          defaultColor: HaboColors.primary,
          importance: NotificationImportance.High,
          criticalAlerts: true),
      // Heads-up channel for actionable habit notifications
      // Uses a light pixel-coin click sound instead of alarm
      NotificationChannel(
          channelKey: 'habit_headsup_habo',
          channelName: 'Habit heads-up reminders',
          channelDescription:
              'Full-screen / heads-up notifications with quick-action buttons',
          defaultColor: HaboColors.primary,
          importance: NotificationImportance.Max,
          criticalAlerts: true,
          locked: true,
          soundSource: 'resource://raw/notification_click',
          playSound: true),
    ],
  );
}

void resetAppNotificationIfMissing(TimeOfDay timeOfDay) async {
  AwesomeNotifications().listScheduledNotifications().then((notifications) {
    for (var not in notifications) {
      if (not.content?.id == 0) {
        return;
      }
    }
    setAppNotification(timeOfDay);
  });
}

void setAppNotification(TimeOfDay timeOfDay) async {
  _setupDailyNotification(0, timeOfDay, 'Habo',
      S.current.doNotForgetToCheckYourHabits, 'app_notifications_habo');
}

void setHabitNotification(
    int id, TimeOfDay timeOfDay, String title, String desc) {
  _setupDailyNotification(
      id, timeOfDay, title, desc, 'habit_notifications_habo');
}

/// Set a smart notification with motivational messages
void setSmartHabitNotification({
  required int id,
  required TimeOfDay timeOfDay,
  required String habitTitle,
  required HabitType habitType,
  int? currentStreak,
  // Meter fields for preset buttons
  double meterMin = 0,
  double meterMax = 10,
  // Diary first question for inline reply hint
  String? firstQuestion,
}) {
  final habitTypeStr = habitType.toString().split('.').last;

  final smartTitle =
      NotificationMessages.buildSmartNotificationTitle(habitTitle, habitTypeStr);
  final smartBody = NotificationMessages.buildSmartNotificationBody(
    habitTitle: habitTitle,
    habitType: habitTypeStr,
    hour: timeOfDay.hour,
    currentStreak: currentStreak,
  );

  _setupHeadsUpNotification(
    id: id,
    timeOfDay: timeOfDay,
    title: smartTitle,
    body: smartBody,
    habitType: habitType,
    meterMin: meterMin,
    meterMax: meterMax,
    firstQuestion: firstQuestion,
  );
}

void disableHabitNotification(int id) {
  if (platformSupportsNotifications()) {
    AwesomeNotifications().cancel(id);
  }
}

void disableAppNotification() {
  AwesomeNotifications().cancel(0);
}

/// Plain daily notification (used for app-level reminders).
Future<void> _setupDailyNotification(int id, TimeOfDay timeOfDay,
    String title, String desc, String channel) async {
  if (platformSupportsNotifications()) {
    String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channel,
        title: title,
        body: desc,
        wakeUpScreen: true,
        criticalAlert: true,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
          hour: timeOfDay.hour,
          minute: timeOfDay.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          preciseAlarm: true,
          timeZone: localTimeZone),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────
/// Heads-up notification with action buttons per habit type.
///
/// * **Boolean** → two buttons: ✓ Done  |  ⏭ Skip
/// * **Meter**   → three preset buttons: Low | Mid | High
/// * **Diary**   → inline text reply (WhatsApp-style)
/// * **Others**  → default heads-up with no extra buttons
/// ─────────────────────────────────────────────────────────────────────
Future<void> _setupHeadsUpNotification({
  required int id,
  required TimeOfDay timeOfDay,
  required String title,
  required String body,
  required HabitType habitType,
  double meterMin = 0,
  double meterMax = 10,
  String? firstQuestion,
}) async {
  if (!platformSupportsNotifications()) return;

  String localTimeZone =
      await AwesomeNotifications().getLocalTimeZoneIdentifier();

  // Build action-buttons based on habit type
  List<NotificationActionButton> actionButtons = [];

  switch (habitType) {
    case HabitType.boolean:
      actionButtons = [
        NotificationActionButton(
          key: 'DONE',
          label: 'Done',
          actionType: ActionType.SilentAction,
          color: HaboColors.primary,
        ),
        NotificationActionButton(
          key: 'SKIP',
          label: 'Skip',
          actionType: ActionType.SilentAction,
          color: HaboColors.skip,
        ),
      ];
      break;

    case HabitType.meter:
      final range = meterMax - meterMin;
      final lowLabel = (meterMin + range * 0.25).toStringAsFixed(0);
      final midLabel = (meterMin + range * 0.5).toStringAsFixed(0);
      final highLabel = (meterMin + range * 0.75).toStringAsFixed(0);
      actionButtons = [
        NotificationActionButton(
          key: 'METER_LOW',
          label: '🔽 $lowLabel',
          actionType: ActionType.SilentAction,
        ),
        NotificationActionButton(
          key: 'METER_MID',
          label: '➡️ $midLabel',
          actionType: ActionType.SilentAction,
        ),
        NotificationActionButton(
          key: 'METER_HIGH',
          label: '🔼 $highLabel',
          actionType: ActionType.SilentAction,
        ),
      ];
      break;

    case HabitType.diary:
      actionButtons = [
        NotificationActionButton(
          key: 'DIARY_REPLY',
          label: firstQuestion ?? '✍️ Write...',
          actionType: ActionType.SilentAction,
          requireInputText: true,
        ),
      ];
      break;

    default:
      // numeric, savings, etc. – just a Done button
      actionButtons = [
        NotificationActionButton(
          key: 'DONE',
          label: '✓ Done',
          actionType: ActionType.SilentAction,
          color: HaboColors.primary,
        ),
      ];
      break;
  }

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: 'habit_headsup_habo',
      title: title,
      body: body,
      wakeUpScreen: true,
      criticalAlert: true,
      fullScreenIntent: true,
      category: NotificationCategory.Alarm,
      payload: {
        'habitType': habitType.toString().split('.').last,
        'habitId': id.toString(),
      },
    ),
    schedule: NotificationCalendar(
      hour: timeOfDay.hour,
      minute: timeOfDay.minute,
      second: 0,
      millisecond: 0,
      repeats: true,
      preciseAlarm: true,
      timeZone: localTimeZone,
    ),
    actionButtons: actionButtons,
  );
}

Future<void> rescheduleNotificationForTomorrow(int originalId) async {
  if (platformSupportsNotifications()) {
    try {
      // Get all scheduled notifications
      final notifications =
          await AwesomeNotifications().listScheduledNotifications();

      // Find the notification with the matching ID
      NotificationModel? existingNotification;
      for (var notification in notifications) {
        if (notification.content?.id == originalId) {
          existingNotification = notification;
          break;
        }
      }

      if (existingNotification != null &&
          existingNotification.content != null) {
        final content = existingNotification.content!;
        final schedule = existingNotification.schedule;

        if (schedule is NotificationCalendar) {
          final tomorrow = DateTime.now().add(const Duration(days: 1));

          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: originalId,
              channelKey: content.channelKey ?? 'habit_headsup_habo',
              title: content.title ?? 'Habo',
              body: content.body ?? '',
              wakeUpScreen: content.wakeUpScreen ?? true,
              criticalAlert: content.criticalAlert ?? true,
              category: content.category ?? NotificationCategory.Alarm,
            ),
            schedule: NotificationCalendar(
              year: tomorrow.year,
              month: tomorrow.month,
              day: tomorrow.day,
              hour: schedule.hour ?? 0,
              minute: schedule.minute ?? 0,
              second: 0,
              millisecond: 0,
              repeats: true,
              preciseAlarm: true,
              timeZone:
                  await AwesomeNotifications().getLocalTimeZoneIdentifier(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling notification: $e');
    }
  }
}

Future<void> rescheduleNotificationForToday(int originalId) async {
  if (platformSupportsNotifications()) {
    try {
      // Get all scheduled notifications
      final notifications =
          await AwesomeNotifications().listScheduledNotifications();

      // Find the notification with the matching ID
      NotificationModel? existingNotification;
      for (var notification in notifications) {
        if (notification.content?.id == originalId) {
          existingNotification = notification;
          break;
        }
      }

      if (existingNotification != null &&
          existingNotification.content != null) {
        final content = existingNotification.content!;
        final schedule = existingNotification.schedule;

        if (schedule is NotificationCalendar) {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: originalId,
              channelKey: content.channelKey ?? 'habit_headsup_habo',
              title: content.title ?? 'Habo',
              body: content.body ?? '',
              wakeUpScreen: content.wakeUpScreen ?? true,
              criticalAlert: content.criticalAlert ?? true,
              category: content.category ?? NotificationCategory.Alarm,
            ),
            schedule: NotificationCalendar(
              hour: schedule.hour ?? 0,
              minute: schedule.minute ?? 0,
              second: 0,
              millisecond: 0,
              repeats: true,
              preciseAlarm: true,
              timeZone:
                  await AwesomeNotifications().getLocalTimeZoneIdentifier(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling notification: $e');
    }
  }
}
