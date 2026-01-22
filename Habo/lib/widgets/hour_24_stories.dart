import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habo/habits/habit.dart';
import 'package:habo/navigation/app_state_manager.dart';
import 'package:habo/widgets/story_detail_modal.dart';
import 'package:provider/provider.dart';

class Hour24Stories extends StatelessWidget {
  final List<Habit> hour24Habits;

  const Hour24Stories({super.key, required this.hour24Habits});

  @override
  Widget build(BuildContext context) {
    if (hour24Habits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: hour24Habits.length,
        itemBuilder: (context, index) {
          final habit = hour24Habits[index];
          return _StoryCircle(habit: habit);
        },
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final Habit habit;

  const _StoryCircle({required this.habit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hoursSinceCreation = now.difference(habit.habitData.createdAt).inHours;
    final minutesSinceCreation = now.difference(habit.habitData.createdAt).inMinutes;
    final hoursRemaining = max(0, 24 - hoursSinceCreation);
    final minutesRemaining = max(0, (24 * 60) - minutesSinceCreation);
    final progress = (minutesSinceCreation / (24 * 60)).clamp(0.0, 1.0);

    // Color based on time remaining
    Color progressColor;
    if (hoursRemaining > 12) {
      progressColor = Colors.green;
    } else if (hoursRemaining > 6) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return GestureDetector(
      // Tap: Show detail modal
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => StoryDetailModal(habit: habit),
        );
      },
      // Long press: Edit habit
      onLongPress: () {
        Provider.of<AppStateManager>(context, listen: false)
            .goEditHabit(habit.habitData);
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(
                      progress: progress,
                      color: progressColor,
                    ),
                  ),
                ),
                // Inner circle with icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        progressColor.withOpacity(0.8),
                        progressColor.withOpacity(0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                // Time remaining badge
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      hoursRemaining > 0
                          ? '${hoursRemaining}h'
                          : '${minutesRemaining}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Habit title
            Text(
              habit.habitData.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 4.0;

    // Background ring
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2; // Start from top
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
