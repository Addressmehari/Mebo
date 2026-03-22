import 'dart:collection';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/generated/l10n.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:habo/model/habit_data.dart';
import 'package:habo/model/category.dart';
import 'package:habo/navigation/app_state_manager.dart';
import 'package:habo/navigation/routes.dart';
import 'package:habo/notifications.dart';
import 'package:habo/settings/settings_manager.dart';
import 'package:habo/widgets/text_container.dart';
import 'package:habo/screens/category_selection_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditHabitScreen extends StatefulWidget {
  static MaterialPage page(HabitData? data) {
    return MaterialPage(
      name: (data != null) ? Routes.editHabitPath : Routes.createHabitPath,
      key: (data != null)
          ? ValueKey(Routes.editHabitPath)
          : ValueKey(Routes.createHabitPath),
      child: EditHabitScreen(habitData: data),
    );
  }

  const EditHabitScreen({super.key, required this.habitData});

  final HabitData? habitData;

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  TextEditingController title = TextEditingController();
  TextEditingController cue = TextEditingController();
  TextEditingController routine = TextEditingController();
  TextEditingController reward = TextEditingController();
  TextEditingController sanction = TextEditingController();
  TextEditingController accountant = TextEditingController();
  TextEditingController targetValue = TextEditingController();
  TextEditingController partialValue = TextEditingController();
  TextEditingController unit = TextEditingController();
  TimeOfDay notTime = const TimeOfDay(hour: 12, minute: 0);
  bool twoDayRule = false;
  bool showReward = false;
  bool advanced = false;
  bool notification = false;
  bool showSanction = false;
  HabitType habitType = HabitType.boolean;
  List<TextEditingController> questionControllers = [];
  List<Category> selectedCategories = [];
  List<String> questions = [];
  List<TimeOfDay> reminders = [];
  
  final List<String> defaultQuestions = [
    "What am I grateful for today?",
    "What was the highlight of my day?",
    "What did I learn today?",
    "What could I have done better?",
    "Mood (1-10)",
    "Notes"
  ];

  // Meter habit fields
  TextEditingController meterMinController = TextEditingController(text: '0');
  TextEditingController meterMaxController = TextEditingController(text: '10');
  List<TextEditingController> meterLabelControllers = [];
  List<String> meterLabels = [];
  
  // 24-hour task flag
  bool is24Hour = false;
  // Secret habit flag
  bool isSecret = false;
  int selectedColor = 0;
  TextEditingController description = TextEditingController();
  bool overlayReminder = false;


  Future<void> _addReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        reminders.add(picked);
        // Keep main notTime synced with first reminder for backward compatibility
        if (reminders.isNotEmpty) {
          notTime = reminders.first;
        }
      });
    }
  }

  Future<void> _editReminder(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminders[index],
    );
    if (picked != null) {
      setState(() {
        reminders[index] = picked;
        if (index == 0) {
          notTime = picked;
        }
      });
    }
  }

  void _removeReminder(int index) {
    setState(() {
      reminders.removeAt(index);
      if (reminders.isNotEmpty) {
        notTime = reminders.first;
      }
    });
  }

  Future<void> setNotificationTime(BuildContext context) async {
    TimeOfDay? selectedTime;
    TimeOfDay initialTime = notTime;
    selectedTime =
        await showTimePicker(context: context, initialTime: initialTime);
    if (selectedTime != null) {
      setState(() {
        notTime = selectedTime!;
      });
    }
  }

  void showSmallTooltip(BuildContext context, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
      dialogType: DialogType.info,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: title,
      desc: desc,
    ).show();
  }

  void showAdvancedTooltip(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
      dialogType: DialogType.info,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
        child: Column(
          children: [
            Text(
              S.of(context).habitLoop,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(
                    text: S.of(context).habitLoopDescription,
                  ),
                  const TextSpan(
                    text: '\n\n',
                  ),
                  TextSpan(
                    text: S.of(context).cue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: S.of(context).cueDescription,
                  ),
                  const TextSpan(
                    text: '\n\n',
                  ),
                  TextSpan(
                    text: S.of(context).routine,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: S.of(context).routineDescription,
                  ),
                  const TextSpan(
                    text: '\n\n',
                  ),
                  TextSpan(
                    text: S.of(context).reward,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: S.of(context).rewardDescription,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).show();
  }

  @override
  void initState() {
    super.initState();
    if (widget.habitData != null) {
      final numberFormatter = NumberFormat('#.##'); // Will remove trailing .0

      title.text = widget.habitData!.title;
      cue.text = widget.habitData!.cue;
      routine.text = widget.habitData!.routine;
      reward.text = widget.habitData!.reward;
      twoDayRule = widget.habitData!.twoDayRule;
      showReward = widget.habitData!.showReward;
      advanced = widget.habitData!.advanced;
      notification = widget.habitData!.notification;
      notTime = widget.habitData!.notTime;
      sanction.text = widget.habitData!.sanction;
      showSanction = widget.habitData!.showSanction;
      accountant.text = widget.habitData!.accountant;
      habitType = widget.habitData!.habitType;
      targetValue.text = numberFormatter.format(widget.habitData!.targetValue);
      partialValue.text =
          numberFormatter.format(widget.habitData!.partialValue);
      unit.text = widget.habitData!.unit;
      selectedCategories = List.from(widget.habitData!.categories);
      questions = List.from(widget.habitData!.questions);
      if (questions.isEmpty && widget.habitData!.isDiary) {
         questions = List.from(defaultQuestions);
      }
      // Initialize meter fields from existing data
      meterMinController.text = widget.habitData!.meterMin.toStringAsFixed(0);
      meterMaxController.text = widget.habitData!.meterMax.toStringAsFixed(0);
      meterLabels = List.from(widget.habitData!.meterLabels);
      is24Hour = widget.habitData!.is24Hour;
      isSecret = widget.habitData!.isSecret;
      selectedColor = widget.habitData!.color;
      reminders = List.from(widget.habitData!.reminders);
      // Fallback for existing habits with single notification
      if (reminders.isEmpty && notification) {
        reminders.add(notTime);
      }
      overlayReminder = widget.habitData!.overlayReminder;
    } else {
      // New habit, set defaults
      questions = List.from(defaultQuestions);
      reminders = [const TimeOfDay(hour: 9, minute: 0)];
    }
    
    // Initialize controllers for each question
    _initQuestionControllers();
    
    // Initialize meter label controllers
    _initMeterLabelControllers();

    // Load categories when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HabitsManager>(context, listen: false).loadCategories();
    });
  }

  void _initQuestionControllers() {
    // Dispose existing controllers first
    for (var controller in questionControllers) {
      controller.dispose();
    }
    questionControllers = questions.map((q) => TextEditingController(text: q)).toList();
  }

  void _addQuestion() {
    setState(() {
      questions.add('');
      questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      questionControllers[index].dispose();
      questionControllers.removeAt(index);
      questions.removeAt(index);
    });
  }

  void _syncQuestionsFromControllers() {
    questions = questionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _initMeterLabelControllers() {
    for (var controller in meterLabelControllers) {
      controller.dispose();
    }
    meterLabelControllers = meterLabels.map((l) => TextEditingController(text: l)).toList();
  }

  void _addMeterLabel() {
    setState(() {
      meterLabels.add('');
      meterLabelControllers.add(TextEditingController());
    });
  }

  void _removeMeterLabel(int index) {
    setState(() {
      meterLabelControllers[index].dispose();
      meterLabelControllers.removeAt(index);
      meterLabels.removeAt(index);
    });
  }

  void _syncMeterLabelsFromControllers() {
    meterLabels = meterLabelControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    title.dispose();
    cue.dispose();
    routine.dispose();
    reward.dispose();
    sanction.dispose();
    accountant.dispose();
    targetValue.dispose();
    partialValue.dispose();
    unit.dispose();
    meterMinController.dispose();
    meterMaxController.dispose();
    for (var controller in questionControllers) {
      controller.dispose();
    }
    for (var controller in meterLabelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final appStateManager =
            Provider.of<AppStateManager>(context, listen: false);
        if (widget.habitData != null) {
          appStateManager.goEditHabit(null);
        } else {
          appStateManager.goCreateHabit(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            (widget.habitData != null)
                ? S.of(context).editHabit
                : S.of(context).createHabit,
          ),
          backgroundColor: Colors.transparent,
          iconTheme: Theme.of(context).iconTheme,
          actions: <Widget>[

            if (widget.habitData != null)
              IconButton(
                icon: Icon(
                  Icons.delete,
                  semanticLabel: S.of(context).delete,
                ),
                color: HaboColors.red,
                tooltip: S.of(context).delete,
                onPressed: () {
                  if (widget.habitData != null) {
                    Provider.of<HabitsManager>(context, listen: false)
                        .deleteHabit(widget.habitData!.id!);
                    Provider.of<AppStateManager>(context, listen: false)
                        .goEditHabit(null);
                  }
                },
              ),
          ],
        ),
        floatingActionButton: Builder(builder: (BuildContext context) {
          return FloatingActionButton(
            onPressed: () {
              if (title.text.isNotEmpty) {
                // Sync questions from controllers
                _syncQuestionsFromControllers();
                // Sync meter labels from controllers
                _syncMeterLabelsFromControllers();

                if (widget.habitData != null) {
                  final habitData = HabitData(
                    id: widget.habitData!.id,
                    title: title.text.toString(),
                    twoDayRule: twoDayRule,
                    cue: cue.text.toString(),
                    routine: routine.text.toString(),
                    reward: reward.text.toString(),
                    showReward: showReward,
                    advanced: advanced,
                    notification: notification,
                    notTime: notTime,
                    position: widget.habitData!.position,
                    events: widget.habitData!.events,
                    sanction: sanction.text.toString(),
                    showSanction: showSanction,
                    accountant: accountant.text.toString(),
                    habitType: habitType,
                    targetValue: double.tryParse(targetValue.text) ?? 100.0,
                    partialValue: double.tryParse(partialValue.text) ?? 10.0,
                    unit: unit.text.toString(),
                    categories: selectedCategories,
                    questions: questions,
                    meterMin: double.tryParse(meterMinController.text) ?? 0.0,
                    meterMax: double.tryParse(meterMaxController.text) ?? 10.0,
                    meterLabels: meterLabels,
                    is24Hour: is24Hour,
                    isSecret: isSecret,
                    createdAt: widget.habitData!.createdAt,
                    color: selectedColor,
                    reminders: reminders,
                    overlayReminder: overlayReminder,
                  );
                  final habitsManager =
                      Provider.of<HabitsManager>(context, listen: false);
                  habitsManager.editHabit(habitData);
                  // Update habit-category associations
                  if (widget.habitData!.id != null) {
                    habitsManager.updateHabitCategories(
                        widget.habitData!.id!, selectedCategories);
                  }
                } else {
                  final habitsManager =
                      Provider.of<HabitsManager>(context, listen: false);
                  habitsManager.addHabit(
                    title.text.toString(),
                    twoDayRule,
                    cue.text.toString(),
                    routine.text.toString(),
                    reward.text.toString(),
                    showReward,
                    advanced,
                    notification,
                    notTime,
                    sanction.text.toString(),
                    showSanction,
                    accountant.text.toString(),
                    habitType: habitType,
                    targetValue: double.tryParse(targetValue.text) ?? 100.0,
                    partialValue: double.tryParse(partialValue.text) ?? 10.0,
                    unit: unit.text.toString(),
                    categories: selectedCategories,
                    questions: questions,
                    meterMin: double.tryParse(meterMinController.text) ?? 0.0,
                    meterMax: double.tryParse(meterMaxController.text) ?? 10.0,
                    meterLabels: meterLabels,
                    is24Hour: is24Hour,
                    isSecret: isSecret,
                    color: selectedColor,
                    reminders: reminders,
                    overlayReminder: overlayReminder,
                  );
                  // For new habits, we need to get the habit ID and then update categories
                  // This will be handled by updating the addHabit method to accept categories
                }
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    behavior: SnackBarBehavior.floating,
                    content: Text(S.of(context).habitTitleEmptyError),
                  ),
                );
              }
            },
            child: Icon(
              Icons.check,
              semanticLabel: S.of(context).save,
              color: Colors.white,
              size: 35.0,
            ),
          );
        }),
        body: Builder(
          builder: (BuildContext context) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  children: <Widget>[
                    TextContainer(
                      title: title,
                      hint: S.of(context).exercise,
                      label: S.of(context).habit,
                    ),

                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 25),
                      title: Text(
                        S.of(context).habitType,
                      ),
                      trailing: DropdownButton<HabitType>(
                        value: habitType,
                        onChanged: (value) {
                          setState(() {
                            habitType = value!;
                          });
                        },
                        icon: const Icon(Icons.expand_more),
                        iconSize: 24,
                        elevation: 16,
                        items: [
                          DropdownMenuItem(
                            value: HabitType.boolean,
                            child: Text(S.of(context).booleanHabit),
                          ),
                          DropdownMenuItem(
                             value: HabitType.diary,
                             child: Text(S.of(context).diaryHabit),
                           ),
                          const DropdownMenuItem(
                             value: HabitType.meter,
                             child: Text('Meter'),
                           ),
                          const DropdownMenuItem(
                            value: HabitType.savings,
                            child: Text('Money Tracker'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),
                    
                    // 24-hour task toggle
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                      leading: Icon(
                        Icons.schedule,
                        color: is24Hour ? Theme.of(context).colorScheme.primary : null,
                      ),
                      title: const Text('24-Hour Task'),
                      subtitle: is24Hour 
                          ? const Text(
                              'This habit will auto-delete after 24 hours',
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            )
                          : null,
                      trailing: Switch(
                        value: is24Hour,
                        onChanged: (value) {
                          setState(() {
                            is24Hour = value;
                          });
                        },
                      ),
                    ),
                    if (is24Hour)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Perfect for daily planning! This task will automatically be deleted 24 hours after creation.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Secret habit toggle
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                      leading: Icon(
                        Icons.lock_outline,
                        color: isSecret ? Theme.of(context).colorScheme.primary : null,
                      ),
                      title: const Text('Secret Habit'),
                      subtitle: isSecret 
                          ? const Text(
                              'Only visible in secret mode',
                              style: TextStyle(fontSize: 12, color: Colors.purple),
                            )
                          : null,
                      trailing: Switch(
                        value: isSecret,
                        onChanged: (value) {
                          setState(() {
                            isSecret = value;
                          });
                        },
                      ),
                    ),
                    
                    // Color Palette Selector
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accent Color',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(HaboColors.habitPalette.length, (index) {
                                final color = HaboColors.habitPalette[index];
                                final isSelected = selectedColor == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedColor = index;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: index == 0 ? Theme.of(context).colorScheme.primary : color,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              width: 2.5)
                                          : Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                      ],
                                    ),
                                    child: isSelected
                                        ? const Center(
                                            child: Icon(Icons.check,
                                                color: Colors.black54,
                                                size: 24),
                                          )
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    if (habitType == HabitType.diary) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                    text: S.of(context).diaryHabitDescription),
                                WidgetSpan(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: GestureDetector(
                                      onTap: () {
                                        showSmallTooltip(
                                            context,
                                            S.of(context).diaryHabit,
                                            S.of(context).diaryHabitDescription);
                                      },
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Diary Questions Header with Add Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Diary Questions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: _addQuestion,
                              icon: const Icon(Icons.add_circle),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'Add Question',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Questions List
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          children: List.generate(questionControllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Question number
                                  Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.only(top: 12, right: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Question text field
                                  Expanded(
                                    child: TextFormField(
                                      controller: questionControllers[index],
                                      decoration: InputDecoration(
                                        hintText: 'Enter question...',
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        suffixIcon: questionControllers.length > 1
                                            ? IconButton(
                                                onPressed: () => _removeQuestion(index),
                                                icon: const Icon(Icons.remove_circle_outline),
                                                color: Colors.red.shade400,
                                                tooltip: 'Remove Question',
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                    if (habitType == HabitType.savings) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: const Text(
                          'Track your wallet balance. Add or subtract money each day.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Min/Max Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: meterMinController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Minimum Balance',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g., 0',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: meterMaxController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Maximum Balance',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g., 1000',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (habitType == HabitType.meter) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: const Text(
                          'Configure the meter range and optional labels.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Min/Max Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: meterMinController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min Value',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: meterMaxController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Value',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Labels header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Custom Labels (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: _addMeterLabel,
                              icon: const Icon(Icons.add_circle),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'Add Label',
                            ),
                          ],
                        ),
                      ),
                      if (meterLabelControllers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            'Labels will be evenly distributed from min to max',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            children: List.generate(meterLabelControllers.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: meterLabelControllers[index],
                                        decoration: InputDecoration(
                                          hintText: 'Label ${index + 1}',
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          suffixIcon: IconButton(
                                            onPressed: () => _removeMeterLabel(index),
                                            icon: const Icon(Icons.remove_circle_outline),
                                            color: Colors.red.shade400,
                                            tooltip: 'Remove Label',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ],
                    if (habitType == HabitType.numeric) ...[
                      Container(
                        // margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0),
                              child: Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      TextSpan(
                                          text: S
                                              .of(context)
                                              .numericHabitDescription),
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 0, 0, 0),
                                          child: GestureDetector(
                                            onTap: () {
                                              showSmallTooltip(
                                                  context,
                                                  S.of(context).numericHabit,
                                                  S
                                                      .of(context)
                                                      .numericHabitDescription);
                                            },
                                            child: const Icon(
                                              Icons.info,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: targetValue,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      labelText: S.of(context).targetValue,
                                      hintText: '100',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: unit,
                                    decoration: InputDecoration(
                                      labelText: S.of(context).unit,
                                      hintText: 'push-ups',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: partialValue,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: S.of(context).partialValue,
                                hintText: '10',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                helperText:
                                    S.of(context).partialValueDescription,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: <Widget>[
                          Checkbox(
                            onChanged: (bool? value) {
                              setState(() {
                                twoDayRule = value ?? false;
                              });
                            },
                            value: twoDayRule,
                          ),
                          Text(S.of(context).useTwoDayRule),
                          IconButton(
                            onPressed: () {
                              showSmallTooltip(
                                  context,
                                  S.of(context).twoDayRule,
                                  S.of(context).twoDayRuleDescription);
                            },
                            icon: const Icon(
                              Icons.info,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Categories Section (conditionally shown)
                    Consumer<SettingsManager>(
                      builder: (context, settingsManager, child) {
                        if (!settingsManager.getShowCategories) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Categories ListTile with plus sign
                            ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                              title: Text(S.of(context).categories),
                              trailing: IconButton(
                                onPressed: () async {
                                  final result = await Navigator.of(context)
                                      .push<List<Category>>(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CategorySelectionScreen(
                                        initialSelectedCategories:
                                            selectedCategories,
                                        onCategoriesChanged: (categories) {
                                          // This callback is called when saving
                                        },
                                      ),
                                    ),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      selectedCategories = result;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add),
                                iconSize: 24,
                              ),
                            ),

                            // Categories chips (styled like category_filter_row.dart)
                            if (selectedCategories.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 4),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: selectedCategories.map((category) {
                                    return FilterChip(
                                      label: Text(
                                        category.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      avatar: Icon(
                                        category.icon,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      selected: true,
                                      onSelected: (selected) {
                                        // Remove category when tapped
                                        setState(() {
                                          selectedCategories.remove(category);
                                        });
                                      },
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      selectedColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                      showCheckmark: false,
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    if (platformSupportsNotifications())
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 25),
                        title: Text(
                          S.of(context).notifications,
                        ),
                        trailing: Switch(
                          value: notification,
                          onChanged: (value) {
                            notification = value;
                            setState(() {});
                          },
                        ),
                      ),
                    if (platformSupportsNotifications())
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 25),
                        enabled: notification,
                        title: Text(
                          S.of(context).notificationTime,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_alarm),
                          onPressed: notification ? _addReminder : null,
                        ),
                      ),
                    
                    if (platformSupportsNotifications() && notification)
                      ...reminders.asMap().entries.map((entry) {
                        final index = entry.key;
                        final time = entry.value;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 40),
                          dense: true,
                          title: Text(
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _editReminder(index),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () => _removeReminder(index),
                                color: HaboColors.red,
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(
                      height: 110,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
