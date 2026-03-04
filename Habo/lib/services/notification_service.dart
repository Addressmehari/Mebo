import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:habo/habits/habit.dart';
import 'package:habo/constants.dart';
import 'package:habo/notifications.dart' as notifications;

/// Service responsible for managing habit notifications
///
/// Extracts notification functionality from HabitsManager to provide
/// a focused, testable service for notification operations.
class NotificationService {
  /// Resets notifications for all provided habits
  ///
  /// Checks existing notifications and habit completion status
  /// to avoid duplicate notifications.
  void resetNotifications(List<Habit> habits) {
    if (!notifications.platformSupportsNotifications()) return;

    // Check existing notifications and habit completion status
    AwesomeNotifications()
        .listScheduledNotifications()
        .then((scheduledNotifications) {
      final existingIds = scheduledNotifications
          .map((n) => n.content?.id)
          .whereType<int>()
          .toSet();

      for (var element in habits) {
        if (element.habitData.notification) {
          var data = element.habitData;

          // Check if habit is already completed for today
          DateTime today = DateTime.now();
          DateTime todayDate = DateTime(today.year, today.month, today.day);
          bool isCompletedToday = false;

          // Check if there's a completed event for today
          data.events.forEach((date, event) {
            if (date.year == todayDate.year &&
                date.month == todayDate.month &&
                date.day == todayDate.day) {
              if (event[0] == DayType.check) {
                isCompletedToday = true;
              }
            }
          });

          // Only schedule notification if not completed today
          if (!isCompletedToday && !existingIds.contains(data.id)) {
            setSmartHabitNotification(
              id: data.id!,
              times: data.allReminders,
              habitTitle: data.title,
              habitType: data.habitType,
              currentStreak: data.streak,
              meterMin: data.meterMin,
              meterMax: data.meterMax,
              firstQuestion: data.questions.isNotEmpty
                  ? data.questions.first
                  : null,
            );
          }
        }
      }
    });
  }

  /// Removes notifications for all provided habits
  void removeNotifications(List<Habit> habits) {
    for (var element in habits) {
      notifications.disableHabitNotification(element.habitData.id!);
    }
  }

  /// Sets a notification for a specific habit
  void setHabitNotification(int id, TimeOfDay time, String title, String desc) {
    // Delegate to global notification function
    notifications.setHabitNotification(id, time, title, desc);
  }

  /// Sets a smart notification with personalized motivational messages
  /// and habit-type-specific action buttons.
  void setSmartHabitNotification({
    required int id,
    required List<TimeOfDay> times,
    required String habitTitle,
    required HabitType habitType,
    int? currentStreak,
    double meterMin = 0,
    double meterMax = 10,
    String? firstQuestion,
  }) {
    // Cancel existing notifications for this habit first to ensure clean state
    disableHabitNotification(id);

    for (int i = 0; i < times.length; i++) {
       // Primary ID is the habit ID itself (backward compatibility)
       // Secondary IDs are derived: id + (index * 100000)
       // Assuming habit IDs won't conflict with this range easily
       final notificationId = (i == 0) ? id : (id + (i * 100000));
       
       notifications.setSmartHabitNotification(
        id: notificationId,
        timeOfDay: times[i],
        habitTitle: habitTitle,
        habitType: habitType,
        currentStreak: currentStreak,
        meterMin: meterMin,
        meterMax: meterMax,
        firstQuestion: firstQuestion,
      );
    }
  }

  /// Disables notification for a specific habit (and all its sub-notifications)
  void disableHabitNotification(int id) {
    // Cancel primary notification
    notifications.disableHabitNotification(id);
    
    // Cancel potential secondary notifications (up to 10)
    for (int i = 1; i <= 10; i++) {
      notifications.disableHabitNotification(id + (i * 100000));
    }
  }

  /// Handles notification rescheduling when a habit event is added
  /// If a habit is marked as completed today, reschedule notification for tomorrow
  void handleHabitEventAdded(int habitId, DateTime eventDate, List event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDateOnly =
        DateTime(eventDate.year, eventDate.month, eventDate.day);

    if (eventDateOnly == today &&
        event.isNotEmpty &&
        event[0] == DayType.check) {
      notifications.rescheduleNotificationForTomorrow(habitId);
    }
  }

  /// Handles notification rescheduling when a habit event is deleted
  /// If an event is deleted for today, reschedule notification for today
  void handleHabitEventDeleted(int habitId, DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDateOnly =
        DateTime(eventDate.year, eventDate.month, eventDate.day);

    if (eventDateOnly == today) {
      notifications.rescheduleNotificationForToday(habitId);
    }
  }
}
