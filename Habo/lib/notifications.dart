import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/generated/l10n.dart';
import 'package:habo/services/notification_messages.dart';

bool platformSupportsNotifications() => Platform.isAndroid || Platform.isIOS;

void initializeNotifications() {
  AwesomeNotifications().initialize(
    null,
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
      NotificationChannel(
          channelKey: 'hour24_notifications_habo',
          channelName: '24-Hour Tasks',
          channelDescription: 'Persistent notifications for 24-hour tasks',
          defaultColor: Colors.orange,
          importance: NotificationImportance.Max,
          locked: true,
          onlyAlertOnce: true, // Only alert on first show, not on updates
          playSound: false,
          enableVibration: false,
          enableLights: false,
          criticalAlerts: false, // Changed to false to avoid sound
          channelShowBadge: true,
          defaultPrivacy: NotificationPrivacy.Public),
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
}) {
  final habitTypeStr = habitType.toString().split('.').last;
  
  final smartTitle = NotificationMessages.buildSmartNotificationTitle(habitTitle, habitTypeStr);
  final smartBody = NotificationMessages.buildSmartNotificationBody(
    habitTitle: habitTitle,
    habitType: habitTypeStr,
    hour: timeOfDay.hour,
    currentStreak: currentStreak,
  );
  
  _setupDailyNotification(
    id, 
    timeOfDay, 
    smartTitle, 
    smartBody, 
    'smart_notifications_habo',
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

Future<void> _setupDailyNotification(int id, TimeOfDay timeOfDay, String title,
    String desc, String channel) async {
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
              channelKey: content.channelKey ?? 'habit_notifications_habo',
              title: content.title ?? 'Habo',
              body: content.body ?? '',
              wakeUpScreen: content.wakeUpScreen ?? true,
              criticalAlert: content.criticalAlert ?? true,
              category: content.category ?? NotificationCategory.Reminder,
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
              channelKey: content.channelKey ?? 'habit_notifications_habo',
              title: content.title ?? 'Habo',
              body: content.body ?? '',
              wakeUpScreen: content.wakeUpScreen ?? true,
              criticalAlert: content.criticalAlert ?? true,
              category: content.category ?? NotificationCategory.Reminder,
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

/// Creates a single aggregated notification showing all 24-hour tasks
/// This creates ONE notification displaying all tasks together
Future<void> createAggregated24HourNotification(dynamic habitsManager) async {
  if (!platformSupportsNotifications()) return;

  // Get all 24-hour tasks
  final all24HourHabits = habitsManager.getAllHabits
      .where((habit) => !habit.habitData.archived && habit.habitData.is24Hour)
      .toList();

  if (all24HourHabits.isEmpty) {
    // No tasks, remove the notification
    await AwesomeNotifications().cancel(999999); // Use fixed ID for aggregate
    return;
  }

  final taskCount = all24HourHabits.length;
  final now = DateTime.now();

  // Build task list for big text
  final taskLines = <String>[];
  for (var habit in all24HourHabits) {
    final elapsed = now.difference(habit.habitData.createdAt);
    final remaining = const Duration(hours: 24) - elapsed;
    final hoursRemaining = remaining.inHours;
    final minutesRemaining = remaining.inMinutes % 60;

    String timeStr;
    if (hoursRemaining > 0) {
      timeStr = '${hoursRemaining}h';
    } else {
      timeStr = '${minutesRemaining}m';
    }

    taskLines.add('⏳ ${habit.habitData.title} ($timeStr)');
  }

  final bigText = taskLines.join('\n');
  final title = taskCount == 1 
      ? '1 Task Active' 
      : '$taskCount Tasks Active';

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 999999, // Fixed ID for the aggregate notification
      channelKey: 'hour24_notifications_habo',
      title: '⏰ 24-Hour Tasks',
      body: title,
      bigPicture: null,
      notificationLayout: NotificationLayout.BigText,
      largeIcon: null,
      wakeUpScreen: false,
      criticalAlert: false,
      category: NotificationCategory.Service,
      locked: true,
      autoDismissible: false,
      displayOnForeground: true,
      displayOnBackground: true,
      showWhen: true,
      backgroundColor: Colors.orange,
      color: Colors.orange,
      payload: {
        'type': '24hour_aggregate',
        'count': taskCount.toString(),
      },
      summary: '$taskCount active',
    ),
  );
}

/// Creates a persistent (non-dismissible) notification for 24-hour tasks
/// The notification remains in the notification tray until the task is completed or deleted
Future<void> create24HourTaskNotification({
  required int habitId,
  required String taskTitle,
  String? description,
}) async {
  // This function is now just a trigger to update the aggregate
  // The actual notification is created by createAggregated24HourNotification
  // which is called by the habits manager
}

/// Updates the 24-hour task notification with remaining time
/// Should be called periodically to update the countdown
Future<void> update24HourTaskNotification({
  required int habitId,
  required String taskTitle,
  required DateTime createdAt,
  String? description,
}) async {
  if (platformSupportsNotifications()) {
    final now = DateTime.now();
    final elapsed = now.difference(createdAt);
    final remaining = const Duration(hours: 24) - elapsed;
    
    if (remaining.isNegative) {
      // Task expired, remove notification
      await remove24HourTaskNotification(habitId);
      return;
    }
    
    final hoursRemaining = remaining.inHours;
    final minutesRemaining = remaining.inMinutes % 60;
    
    String timeRemaining;
    Color color;
    
    if (hoursRemaining > 12) {
      timeRemaining = '$hoursRemaining hours remaining';
      color = Colors.green;
    } else if (hoursRemaining > 6) {
      timeRemaining = hoursRemaining > 0
          ? '$hoursRemaining hours remaining'
          : '$minutesRemaining minutes remaining';
      color = Colors.orange;
    } else {
      timeRemaining = hoursRemaining > 0
          ? '$hoursRemaining hours $minutesRemaining min remaining'
          : '$minutesRemaining minutes remaining';
      color = Colors.red;
    }
    
    final body = description != null && description.isNotEmpty
        ? '$description\n⏰ $timeRemaining'
        : '⏰ $timeRemaining';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: habitId,
        channelKey: 'hour24_notifications_habo',
        title: '⏳ $taskTitle',
        body: body,
        wakeUpScreen: false,
        criticalAlert: false,
        category: NotificationCategory.Service,
        notificationLayout: NotificationLayout.Default,
        locked: true,
        autoDismissible: false,
        showWhen: true,
        backgroundColor: color,
        color: color,
        groupKey: '24hour_tasks_group', // Groups all 24-hour tasks together
        payload: {
          'habitId': habitId.toString(),
          'type': '24hour_task',
        },
        summary: '24-Hour Tasks', // Summary shown in collapsed group
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'COMPLETE',
          label: 'Complete',
          actionType: ActionType.Default,
          color: Colors.green,
        ),
        NotificationActionButton(
          key: 'SKIP',
          label: 'Skip',
          actionType: ActionType.Default,
          color: Colors.orange,
        ),
      ],
    );
  }
}

/// Removes the 24-hour task notification
Future<void> remove24HourTaskNotification(int habitId) async {
  if (platformSupportsNotifications()) {
    await AwesomeNotifications().cancel(habitId);
  }
}

/// Sets up listeners to recreate 24-hour notifications when dismissed
/// This mimics the behavior of Android system notifications like hotspot
void setup24HourNotificationListeners(dynamic habitsManager) {
  if (!platformSupportsNotifications()) return;

  // Listen for notification dismissals
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: (ReceivedAction receivedAction) async {
      // Handle action button presses (Complete/Skip) - not used in aggregated view
      // Actions are handled through the app UI
    },
    onDismissActionReceivedMethod: (ReceivedAction receivedAction) async {
      // Check if this is the aggregated 24-hour task notification
      final payload = receivedAction.payload;
      if (payload != null && payload['type'] == '24hour_aggregate') {
        // Wait a moment before recreating to avoid visual glitch
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Recreate the aggregated notification
        await createAggregated24HourNotification(habitsManager);
      }
    },
  );
}
