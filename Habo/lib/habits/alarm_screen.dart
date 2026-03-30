import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:habo/model/habit_data.dart';
import 'package:habo/navigation/routes.dart';
import 'package:habo/navigation/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habo/helpers.dart';
import 'package:habo/generated/l10n.dart';

class AlarmScreen extends StatefulWidget {
  final int habitId;

  const AlarmScreen({super.key, required this.habitId});

  static MaterialPage page({required int habitId}) {
    return MaterialPage(
      name: Routes.alarmPath,
      key: ValueKey('${Routes.alarmPath}_$habitId'),
      child: AlarmScreen(habitId: habitId),
    );
  }

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  double _meterValue = 5.0;
  final Map<String, TextEditingController> _diaryControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _diaryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleAction(DayType type, [dynamic value]) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final habitsManager = Provider.of<HabitsManager>(context, listen: false);
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    
    final today = DateTime.now();
    
    List eventData;
    if (type == DayType.meter) {
      eventData = [DayType.meter, '', value ?? _meterValue];
    } else if (type == DayType.check && value is String) {
      eventData = [DayType.check, value];
    } else {
      eventData = [type, ''];
    }

    habitsManager.completeHabitFromNotification(widget.habitId, today, eventData);
    
    // Close the alarm screen
    appStateManager.goAlarm(null);
    
    // Quit the app automatically as requested
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final habitsManager = Provider.of<HabitsManager>(context);
    final habit = habitsManager.findHabitById(widget.habitId);
    
    if (habit == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = habit.habitData;
    final themeColor = HaboColors.getHabitColor(data.color, Theme.of(context).primaryColor);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          _buildBackground(themeColor),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildHeader(data),
                      const Spacer(),
                      _buildInteractionArea(data, themeColor),
                      const Spacer(),
                      _buildBottomActions(data),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor.withOpacity(0.3),
            Colors.black,
            Colors.black,
            themeColor.withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(HabitData data) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
          ),
          child: Icon(
            _getHabitIcon(data.habitType),
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.righteous(
            fontSize: 36,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (data.cue.isNotEmpty)
          Text(
            data.cue,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildInteractionArea(HabitData data, Color themeColor) {
    switch (data.habitType) {
      case HabitType.boolean:
        return _buildBooleanInteraction(themeColor);
      case HabitType.meter:
        return _buildMeterInteraction(data, themeColor);
      case HabitType.diary:
        return _buildDiaryInteraction(data, themeColor);
      case HabitType.numeric:
        return _buildNumericInteraction(data, themeColor);
      case HabitType.savings:
        return _buildSavingsInteraction(data, themeColor);
    }
  }

  Widget _buildBooleanInteraction(Color themeColor) {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.check_circle_outline,
          label: 'DONE',
          color: themeColor,
          onTap: () => _handleAction(DayType.check),
        ),
        const SizedBox(height: 20),
        _buildActionCard(
          icon: Icons.cancel_outlined,
          label: 'NOT DONE',
          color: Colors.redAccent,
          onTap: () => _handleAction(DayType.fail),
        ),
      ],
    );
  }

  Widget _buildMeterInteraction(HabitData data, Color themeColor) {
    final int min = data.meterMin.toInt();
    final int max = data.meterMax.toInt();
    final int divisions = max - min;
    
    return Column(
      children: [
        _buildGlassCard(
          child: Column(
            children: [
              Text(
                _meterValue.round().toString(),
                style: GoogleFonts.righteous(fontSize: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: themeColor,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: themeColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: _meterValue,
                  min: data.meterMin,
                  max: data.meterMax,
                  divisions: divisions > 0 ? divisions : null,
                  onChanged: (v) => setState(() => _meterValue = v.roundToDouble()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(min.toString(), style: const TextStyle(color: Colors.white60)),
                    Text(max.toString(), style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          label: 'LOG VALUE',
          color: themeColor,
          onTap: () => _handleAction(DayType.meter, _meterValue.roundToDouble()),
        ),
      ],
    );
  }

  Widget _buildDiaryInteraction(HabitData data, Color themeColor) {
    if (data.questions.isEmpty) return const Text("No questions set", style: TextStyle(color: Colors.white));
    
    final question = data.questions.first;
    if (!_diaryControllers.containsKey(question)) {
      _diaryControllers[question] = TextEditingController();
    }

    return Column(
      children: [
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _diaryControllers[question],
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your thoughts...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          label: 'SAVE ENTRY',
          color: themeColor,
          onTap: () {
            final text = _diaryControllers[question]!.text.trim();
            if (text.isNotEmpty) {
              final diaryData = jsonEncode({question: text});
              _handleAction(DayType.check, diaryData);
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildNumericInteraction(HabitData data, Color themeColor) {
    return _buildBooleanInteraction(themeColor);
  }
  
  Widget _buildSavingsInteraction(HabitData data, Color themeColor) {
     return _buildBooleanInteraction(themeColor);
  }

  Widget _buildBottomActions(HabitData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSecondaryButton(
          icon: Icons.skip_next,
          label: 'SKIP TODAY',
          onTap: () => _handleAction(DayType.skip),
        ),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassCard(
        color: color.withOpacity(0.15),
        borderColor: color.withOpacity(0.3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.righteous(fontSize: 20, color: color, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, Color? color, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.righteous(fontSize: 18, letterSpacing: 2),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white60),
      label: Text(label, style: const TextStyle(color: Colors.white60)),
    );
  }

  IconData _getHabitIcon(HabitType type) {
    switch (type) {
      case HabitType.boolean: return Icons.task_alt;
      case HabitType.numeric: return Icons.bar_chart;
      case HabitType.diary: return Icons.auto_stories;
      case HabitType.meter: return Icons.speed;
      case HabitType.savings: return Icons.savings;
    }
  }
}
