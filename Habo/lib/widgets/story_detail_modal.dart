import 'package:flutter/material.dart';
import 'package:habo/habits/habit.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:habo/constants.dart';
import 'package:provider/provider.dart';

class StoryDetailModal extends StatefulWidget {
  final Habit habit;

  const StoryDetailModal({super.key, required this.habit});

  @override
  State<StoryDetailModal> createState() => _StoryDetailModalState();
}

class _StoryDetailModalState extends State<StoryDetailModal> {
  
  void _completeTask() {
    final habitsManager = Provider.of<HabitsManager>(context, listen: false);
    
    // Mark the habit as completed for today
    habitsManager.addEvent(
      widget.habit.habitData.id!,
      DateTime.now(),
      [DayType.check, 'Completed via story'],
    );
    
    // Close modal immediately
    Navigator.of(context).pop();
    
    // Delete the habit silently (no undo snackbar)
    Future.delayed(const Duration(milliseconds: 500), () {
      habitsManager.deleteHabit(widget.habit.habitData.id!, silent: true);
    });
  }

  void _skipTask() {
    final habitsManager = Provider.of<HabitsManager>(context, listen: false);
    // Mark as skipped
    habitsManager.addEvent(
      widget.habit.habitData.id!,
      DateTime.now(),
      [DayType.skip, 'Skipped via story'],
    );
    
    // Delete the 24-hour habit silently (no undo snackbar)
    habitsManager.deleteHabit(widget.habit.habitData.id!, silent: true);
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minutesRemaining = (24 * 60) - now.difference(widget.habit.habitData.createdAt).inMinutes;
    final hoursRemaining = (minutesRemaining / 60).floor();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with progress ring indicator
            Row(
              children: [
                // Mini progress indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: hoursRemaining > 12
                          ? [Colors.green, Colors.green.shade300]
                          : hoursRemaining > 6
                              ? [Colors.orange, Colors.orange.shade300]
                              : [Colors.red, Colors.red.shade300],
                    ),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.habitData.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hoursRemaining > 0
                            ? '$hoursRemaining hours remaining'
                            : '$minutesRemaining minutes remaining',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (widget.habit.habitData.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.habit.habitData.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipTask,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.orange.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: 20, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _completeTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
