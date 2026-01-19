import 'package:flutter/material.dart';
import 'package:habo/constants.dart';

class MeterInputModal extends StatefulWidget {
  final String habitTitle;
  final double meterMin;
  final double meterMax;
  final List<String> meterLabels;
  final double currentValue;
  final Function(double) onValueChanged;

  const MeterInputModal({
    super.key,
    required this.habitTitle,
    required this.meterMin,
    required this.meterMax,
    required this.meterLabels,
    required this.currentValue,
    required this.onValueChanged,
  });

  @override
  State<MeterInputModal> createState() => _MeterInputModalState();
}

class _MeterInputModalState extends State<MeterInputModal> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.currentValue.clamp(widget.meterMin, widget.meterMax);
  }

  String _getLabelForValue(double value) {
    if (widget.meterLabels.isEmpty) {
      return value.toStringAsFixed(0);
    }
    
    // Map value to label index
    final range = widget.meterMax - widget.meterMin;
    final normalized = (value - widget.meterMin) / range;
    final index = (normalized * (widget.meterLabels.length - 1)).round();
    final clampedIndex = index.clamp(0, widget.meterLabels.length - 1);
    return widget.meterLabels[clampedIndex];
  }

  int get _divisions {
    if (widget.meterLabels.isNotEmpty) {
      return widget.meterLabels.length - 1;
    }
    return (widget.meterMax - widget.meterMin).round();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.habitTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Current value display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getLabelForValue(_currentValue),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: HaboColors.primary,
              inactiveTrackColor: HaboColors.primary.withOpacity(0.3),
              thumbColor: HaboColors.primary,
              overlayColor: HaboColors.primary.withOpacity(0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _currentValue,
              min: widget.meterMin,
              max: widget.meterMax,
              divisions: _divisions > 0 ? _divisions : null,
              onChanged: (value) {
                setState(() {
                  _currentValue = value;
                });
              },
            ),
          ),
          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.meterLabels.isNotEmpty 
                      ? widget.meterLabels.first 
                      : widget.meterMin.toStringAsFixed(0),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.meterLabels.isNotEmpty 
                      ? widget.meterLabels.last 
                      : widget.meterMax.toStringAsFixed(0),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onValueChanged(_currentValue);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
