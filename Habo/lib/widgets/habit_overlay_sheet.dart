import 'package:flutter/material.dart';
import 'package:habo/model/habit_data.dart';
import 'package:habo/constants.dart';

class HabitOverlaySheet extends StatelessWidget {
  final HabitData habit;
  final Function(bool) onBooleanComplete;
  final Function(double) onMeterComplete;

  const HabitOverlaySheet({
    super.key,
    required this.habit,
    required this.onBooleanComplete,
    required this.onMeterComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Text(
            'Habit Reminder',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            habit.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (habit.cue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Cue: ${habit.cue}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          
          if (habit.isBoolean) _buildBooleanContent(context),
          if (habit.isMeter) _buildMeterContent(context),
          
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe later'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBooleanContent(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              onBooleanComplete(false);
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: HaboColors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Not Done',
              style: TextStyle(color: HaboColors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              onBooleanComplete(true);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: HaboColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeterContent(BuildContext context) {
    // For local state in a stateless widget, we could use a StatefulBuilder
    double tempValue = habit.meterMin;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Text(
              tempValue.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Slider(
              value: tempValue,
              min: habit.meterMin,
              max: habit.meterMax,
              divisions: (habit.meterMax - habit.meterMin).toInt() * 2,
              onChanged: (value) {
                setState(() {
                  tempValue = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(habit.meterMin.toStringAsFixed(0)),
                Text(habit.meterMax.toStringAsFixed(0)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onMeterComplete(tempValue);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: HaboColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Progress',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void show(BuildContext context, HabitData habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitOverlaySheet(
        habit: habit,
        onBooleanComplete: (done) {
          // TODO: Implement completion logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(done ? 'Habit marked as done!' : 'Habit marked as NOT done')),
          );
        },
        onMeterComplete: (value) {
          // TODO: Implement meter logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Meter value saved: $value')),
          );
        },
      ),
    );
  }
}
