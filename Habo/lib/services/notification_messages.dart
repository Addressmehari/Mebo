import 'dart:math';

/// Collection of motivational messages for smart notifications
class NotificationMessages {
  static final Random _random = Random();

  /// Morning motivational messages (6 AM - 12 PM)
  static const List<String> morningMessages = [
    "Rise and shine! 🌅 Time for",
    "Good morning! Start your day right with",
    "A new day, a new opportunity! Don't forget",
    "Morning achievers know: consistency wins! Time for",
    "Your future self will thank you. Let's do",
    "Champions start early! Ready for",
  ];

  /// Afternoon motivational messages (12 PM - 6 PM)
  static const List<String> afternoonMessages = [
    "Halfway through the day! Don't forget",
    "Afternoon check-in: Have you done",
    "Keep the momentum going with",
    "Great progress today! Remember to do",
    "Stay focused! Time for",
  ];

  /// Evening motivational messages (6 PM - 10 PM)
  static const List<String> eveningMessages = [
    "Wind down your day with",
    "Before the day ends, complete",
    "Evening routine time! Don't skip",
    "One more thing before you relax:",
    "Finish strong! Don't forget",
  ];

  /// Streak-based messages
  static const List<String> streakProtectionMessages = [
    "🔥 Don't break your {streak}-day streak!",
    "💪 {streak} days strong! Keep going!",
    "⚡ You're on fire! {streak} days in a row!",
    "🏆 {streak}-day streak at risk! Quick, do",
    "🎯 Almost losing your {streak}-day streak!",
  ];

  /// Messages for habits not done yet today
  static const List<String> urgentMessages = [
    "⏰ Running out of time! Don't forget",
    "🚨 Almost missed! Quick,",
    "⌛ Last chance today!",
    "📢 Final reminder for",
  ];

  /// Messages for diary habits
  static const List<String> diaryMessages = [
    "📝 Take a moment to reflect. Write in",
    "✍️ How was your day? Open",
    "💭 Capture your thoughts in",
    "📖 Your future self will love reading this:",
  ];

  /// Messages for meter habits
  static const List<String> meterMessages = [
    "📊 How are you feeling? Track",
    "📈 Quick check-in time for",
    "🎚️ Rate your day:",
  ];

  /// Get a random message based on time of day
  static String getTimeBasedMessage(int hour) {
    List<String> messages;
    if (hour >= 6 && hour < 12) {
      messages = morningMessages;
    } else if (hour >= 12 && hour < 18) {
      messages = afternoonMessages;
    } else if (hour >= 18 && hour < 22) {
      messages = eveningMessages;
    } else {
      // Late night/early morning - use morning messages
      messages = morningMessages;
    }
    
    return messages[_random.nextInt(messages.length)];
  }

  /// Get a streak protection message
  static String getStreakMessage(int streak) {
    final template = streakProtectionMessages[_random.nextInt(streakProtectionMessages.length)];
    return template.replaceAll('{streak}', streak.toString());
  }

  /// Get an urgent message for late in the day
  static String getUrgentMessage() {
    return urgentMessages[_random.nextInt(urgentMessages.length)];
  }

  /// Get a message for diary habits
  static String getDiaryMessage() {
    return diaryMessages[_random.nextInt(diaryMessages.length)];
  }

  /// Get a message for meter habits
  static String getMeterMessage() {
    return meterMessages[_random.nextInt(meterMessages.length)];
  }

  /// Build a complete smart notification body
  static String buildSmartNotificationBody({
    required String habitTitle,
    required String habitType, // 'boolean', 'numeric', 'diary', 'meter'
    required int hour,
    int? currentStreak,
  }) {
    String prefix;
    final isLateInDay = hour >= 20;
    
    // Check for urgent situation first
    if (isLateInDay) {
      prefix = getUrgentMessage();
    }
    // Check for streak at risk
    else if (currentStreak != null && currentStreak >= 3) {
      prefix = getStreakMessage(currentStreak);
      return '$prefix $habitTitle';
    }
    // Habit type specific messages
    else if (habitType == 'diary') {
      prefix = getDiaryMessage();
    }
    else if (habitType == 'meter') {
      prefix = getMeterMessage();
    }
    // Default time-based message
    else {
      prefix = getTimeBasedMessage(hour);
    }
    
    return '$prefix $habitTitle';
  }

  /// Get emoji for habit type
  static String getHabitEmoji(String habitType) {
    switch (habitType) {
      case 'diary':
        return '📝';
      case 'meter':
        return '📊';
      case 'numeric':
        return '🔢';
      default:
        return '✅';
    }
  }

  /// Build notification title with emoji
  static String buildSmartNotificationTitle(String habitTitle, String habitType) {
    final emoji = getHabitEmoji(habitType);
    return '$emoji $habitTitle';
  }
}
