import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MoneyInputModal extends StatefulWidget {
  final String habitTitle;
  final double currentBalance;
  final Function(double) onValueChanged;

  const MoneyInputModal({
    super.key,
    required this.habitTitle,
    required this.currentBalance,
    required this.onValueChanged,
  });

  @override
  State<MoneyInputModal> createState() => _MoneyInputModalState();
}

class _MoneyInputModalState extends State<MoneyInputModal> {
  late TextEditingController _amountController;
  late double _newBalance;
  bool _isAdding = true;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _newBalance = widget.currentBalance;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateBalance() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      if (_isAdding) {
        _newBalance = widget.currentBalance + amount;
      } else {
        _newBalance = widget.currentBalance - amount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.habitTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Current Balance Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.savings, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '₹${widget.currentBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Add/Subtract Toggle
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Add'),
                    icon: Icon(Icons.add, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Subtract'),
                    icon: Icon(Icons.remove, size: 16),
                  ),
                ],
                selected: {_isAdding},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isAdding = newSelection.first;
                    _updateBalance();
                  });
                },
              ),
              const SizedBox(height: 16),
              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _amountController.clear();
                      _updateBalance();
                    },
                  ),
                ),
                onChanged: (value) => _updateBalance(),
              ),
              const SizedBox(height: 16),
              // New Balance Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isAdding ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isAdding ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      'New Balance:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _isAdding ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                    Text(
                      '₹${_newBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isAdding ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onValueChanged(_newBalance);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
