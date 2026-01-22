# 24-Hour Task Feature

## Overview

Added a new feature that allows users to create temporary tasks/habits that automatically delete after 24 hours. Perfect for daily planning and one-time tasks!

## How It Works

### User Experience

1. **Toggle in Habit Creation**: When creating/editing a habit, there's now a "24-Hour Task" toggle with a clock icon
2. **Visual Indicators**:
   - When enabled, the toggle shows with the primary theme color
   - A subtitle appears: "This habit will auto-delete after 24 hours"
   - An info box explains: "Perfect for daily planning! This task will automatically be deleted 24 hours after creation."
3. **Auto-Deletion**: The habit automatically deletes 24 hours after creation

### Technical Implementation

#### Database Changes (Version 11)

- **New Columns**:
  - `is24Hour` (INTEGER): Flag to mark temporary tasks
  - `createdAt` (TEXT): Timestamp when habit was created
- **Migration**: Automatically adds these columns to existing databases

#### Files Modified

1. **`habit_data.dart`**
   - Added `is24Hour` boolean field
   - Added `createdAt` DateTime field
   - Both included in constructor with defaults

2. **`habo_model.dart`**
   - Database version bumped to 11
   - Created `_createTableHabitsV11()` with new columns
   - Added `_updateTableHabitsAdd24HourFields()` for migration
   - Updated `_onCreate()` to use V11 schema
   - Updated `_onUpgrade()` to handle migration
   - Updated `getAllHabits()` to parse new fields

3. **`habit.dart`**
   - Updated `toMap()` to include is24Hour and createdAt
   - Updated `toJson()` to include both fields (for backups)
   - Updated `fromJson()` to parse both fields

4. **`habits_manager.dart`**
   - Added `is24Hour` parameter to `addHabit()`
   - Added fields to `editHabit()`
   - Created `_deleteExpired24HourHabits()` method
   - Integrated deletion check in `checkDayChange()`
   - Auto-deletion runs every midnight

5. **`edit_habit_screen.dart`**
   - Added `is24Hour` state variable
   - Added UI toggle with icon and explanatory text
   - Loads value from existing habits
   - Saves value when creating/editing
   - Shows helpful info box when enabled

## Auto-Deletion Logic

The deletion happens in `_deleteExpired24HourHabits()`:

1. Runs automatically on day change (midnight)
2. Checks all habits with `is24Hour = true`
3. Calculates hours since creation
4. Deletes habits older than 24 hours
5. Removes from database and disables notifications
6. Updates habit order

## Use Cases

- **Daily Planning**: Add today's tasks that don't need to persist
- **One-Time Events**: Create reminders for specific activities
- **Temporary Goals**: Short-term objectives that don't clutter your habit list
- **Quick Tasks**: Add quick to-dos without manual cleanup

## Future Enhancements (Optional)

- Custom duration (12 hours, 48 hours, etc.)
- Warning notification before deletion
- Option to convert to permanent habit
- Deleted habit archive/history

## Testing

1. Create a new habit and enable "24-Hour Task"
2. Verify the toggle shows correctly
3. Save the habit
4. Wait 24+ hours or manually trigger day change
5. Confirm habit is auto-deleted

## Notes

- Existing habits default to `is24Hour = false`
- Migration is backward compatible
- Deletion only happens on day change check
- Hot reload during development won't trigger deletion (need actual day change)
