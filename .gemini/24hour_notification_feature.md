# 24-Hour Task Persistent Notification Feature

## Overview
This feature adds **persistent, non-dismissible notifications** for 24-hour temporary tasks that cannot be swiped away by the user. The notification remains in the notification tray until the task is completed, skipped, or expires.

## Implementation Details

### 1. New Notification Channel
**File:** `lib/notifications.dart`

Added a dedicated notification channel for 24-hour tasks:
- **Channel Key:** `hour24_notifications_habo`
- **Channel Name:** "24-Hour Tasks"
- **Properties:**
  - `importance: NotificationImportance.Max` - High priority
  - `locked: true` - Makes notifications persistent
  - `criticalAlerts: true` - Ensures visibility
  - `defaultColor: Colors.orange` - Orange color scheme

### 2. Notification Functions

#### `create24HourTaskNotification()`
Creates the initial persistent notification when a 24-hour task is created.

**Features:**
- Shows task title with ⏳ emoji
- Displays description (if provided)
- Shows "24 hours remaining" initially
- Cannot be dismissed by swiping
- Orange background color
- Payload includes habit ID and expiry time

#### `update24HourTaskNotification()`
Updates the notification with remaining time (optional feature for future use).

**Features:**
- Calculates time remaining dynamically
- Color-coded by urgency:
  - **Green**: >12 hours remaining
  - **Orange**: 6-12 hours remaining
  - **Red**: <6 hours remaining
- Shows hours/minutes remaining
- Can be called periodically to update countdown

#### `remove24HourTaskNotification()`
Removes the notification when the task is completed, skipped, or deleted.

### 3. Service Layer Integration
**File:** `lib/services/notification_service.dart`

Added three new methods to `NotificationService` class:
- `create24HourTaskNotification()` - Wrapper for creation
- `update24HourTaskNotification()` - Wrapper for updates
- `remove24HourTaskNotification()` - Wrapper for removal

### 4. Business Logic Integration
**File:** `lib/habits/habits_manager.dart`

#### When Creating a 24-Hour Task (`addHabit`)
```dart
if (is24Hour) {
  // Create persistent notification for 24-hour tasks
  _notificationService?.create24HourTaskNotification(
    habitId: id,
    taskTitle: title,
    description: cue, // Use cue field as description
  );
}
```

#### When Deleting a Task (`deleteFromDB`)
```dart
if (habitToDelete.habitData.is24Hour) {
  _notificationService?.remove24HourTaskNotification(habitToDelete.habitData.id!);
} else {
  _notificationService?.disableHabitNotification(habitToDelete.habitData.id!);
}
```

#### When Tasks Expire (`_deleteExpired24HourHabits`)
```dart
_notificationService?.remove24HourTaskNotification(habit.habitData.id!);
```

## User Flow

### Creating a 24-Hour Task
1. User opens "Create Habit" screen
2. User enables "24-Hour Task" toggle
3. User enters task title and optional description (in "Cue" field)
4. User saves the task
5. **Persistent notification appears immediately**
6. Notification shows "⏳ [Task Title]" with "24 hours remaining"

### Completing a Task
1. User taps on the story circle on home screen
2. Modal shows task details
3. User taps "Complete" button
4. Task is marked as completed in statistics
5. Task is deleted from database
6. **Notification is automatically removed**

### Skipping a Task
1. User taps on the story circle
2. User taps "Skip" button
3. Task is marked as skipped in statistics
4. Task is deleted from database
5. **Notification is automatically removed**

### Task Expiration
1. App checks for expired tasks at midnight
2. Tasks older than 24 hours are identified
3. Tasks are deleted from database
4. **Notifications are automatically removed**

## Technical Implementation

### Notification Properties
```dart
NotificationContent(
  id: habitId,
  channelKey: 'hour24_notifications_habo',
  title: '⏳ $taskTitle',
  body: '$description\n⏰ $timeRemaining',
  locked: true,              // ← Makes it non-dismissible
  autoDismissible: false,    // ← Prevents auto-dismissal
  wakeUpScreen: false,       // Doesn't wake screen
  criticalAlert: false,      // Not critical alert
  category: NotificationCategory.Reminder,
  backgroundColor: Colors.orange,
)
```

### Key Parameters
- **locked: true** - Prevents user from swiping away the notification
- **autoDismissible: false** - Notification stays until explicitly removed
- **id: habitId** - Uses habit ID as notification ID for easy removal

## Files Modified

1. **lib/notifications.dart**
   - Added new notification channel
   - Added `create24HourTaskNotification()` function
   - Added `update24HourTaskNotification()` function
   - Added `remove24HourTaskNotification()` function

2. **lib/services/notification_service.dart**
   - Added wrapper methods for 24-hour notifications

3. **lib/habits/habits_manager.dart**
   - Updated `addHabit()` to create notification for 24-hour tasks
   - Updated `deleteFromDB()` to remove appropriate notification type
   - Updated `_deleteExpired24HourHabits()` to remove notifications

## Future Enhancements (Optional)

1. **Periodic Updates**
   - Could implement a background service to update notification text with remaining time
   - Would require WorkManager or similar background task scheduler

2. **Action Buttons**
   - Add "Complete" and "Skip" buttons directly in the notification
   - Would require notification action handlers

3. **Notification Sounds**
   - Could add alerts at specific milestones (12h, 6h, 1h remaining)

4. **Customization**
   - Allow users to choose notification style/color
   - Option to enable/disable persistent notifications

## Testing Checklist

- [x] Create a 24-hour task → Notification appears
- [ ] Notification cannot be swiped away
- [ ] Complete task from story modal → Notification disappears
- [ ] Skip task from story modal → Notification disappears
- [ ] Wait 24 hours → Task and notification auto-delete
- [ ] Multiple 24-hour tasks show separate notifications
- [ ] App restart → Notifications persist
- [ ] Notifications survive device reboot (if supported by OS)

## Notes

- The notification uses the **cue** field as the description for 24-hour tasks
- Notification ID matches the habit ID for easy cleanup
- The `locked` property requires Android API level 21+ (already supported by the app)
- iOS may have different behavior for persistent notifications (depends on iOS version)

## Troubleshooting

### Notification Not Showing
- Check notification permissions are granted
- Verify channel is properly initialized
- Check platform supports notifications (Android/iOS only)

### Notification Can Be Dismissed
- Verify `locked: true` is set
- Check Android version (some versions may ignore this)
- Ensure using the correct notification channel

### Notification Not Removed
- Check habit ID is correctly passed
- Verify `remove24HourTaskNotification()` is called
- Check for any errors in notification service

---

**Implementation Date:** 2026-01-23  
**Feature Status:** ✅ Complete
