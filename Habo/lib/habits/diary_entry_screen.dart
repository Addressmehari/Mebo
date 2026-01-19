import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/generated/l10n.dart'; // Make sure this is available after generation
// If S is not updated, we might need to rely on hardcoded strings temporarily or rerun generation
// For now, I'll use S.of(context) assuming generation works, or fallback

class DiaryEntryScreen extends StatefulWidget {
  final String habitTitle;
  final DateTime date;
  final String? existingData;
  final Function(String result) onSave;

  const DiaryEntryScreen({
    super.key,
    required this.habitTitle,
    required this.date,
    this.existingData,
    required this.onSave,
  });

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  // Default questions for the grid diary
  final List<String> questions = [
    "What am I grateful for today?",
    "What was the highlight of my day?",
    "What did I learn today?",
    "What could I have done better?",
    "Mood (1-10)",
    "Notes"
  ];

  Map<String, String> answers = {};
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null && widget.existingData!.isNotEmpty) {
      try {
        final decoded = jsonDecode(widget.existingData!);
        if (decoded is Map<String, dynamic>) {
          answers = decoded.map((key, value) => MapEntry(key, value.toString()));
        }
      } catch (e) {
        // Fallback for plain text legacy comments
        answers["Notes"] = widget.existingData!;
      }
    }

    // Initialize controllers
    for (var question in questions) {
      _controllers[question] = TextEditingController(text: answers[question] ?? "");
      _controllers[question]!.addListener(() {
        answers[question] = _controllers[question]!.text;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${widget.habitTitle}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final jsonString = jsonEncode(answers);
              widget.onSave(jsonString);
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '${widget.date.day}/${widget.date.month}/${widget.date.year}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
              ),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Question
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16.0),
                            topRight: Radius.circular(16.0),
                          ),
                        ),
                        child: Text(
                          question,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.0,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Input Area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: TextField(
                            controller: _controllers[question],
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: "Write here...",
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
