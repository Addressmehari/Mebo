import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:habo/model/category.dart';
import 'package:habo/model/habit_data.dart';
import 'package:habo/habits/habit_header.dart';
import 'package:habo/habits/one_day.dart';
import 'package:habo/habits/one_day_button.dart';
import 'package:habo/helpers.dart';
import 'package:habo/constants.dart';
import 'package:habo/generated/l10n.dart';
import 'package:habo/navigation/app_state_manager.dart';
import 'package:habo/settings/settings_manager.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habo/extensions.dart';

class Habit extends StatefulWidget {
  const Habit({super.key, required this.habitData});

  final HabitData habitData;

  set setId(int input) {
    habitData.id = input;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': habitData.id,
      'title': habitData.title,
      'twoDayRule': habitData.twoDayRule ? 1 : 0,
      'position': habitData.position,
      'cue': habitData.cue,
      'routine': habitData.routine,
      'reward': habitData.reward,
      'showReward': habitData.showReward ? 1 : 0,
      'advanced': habitData.advanced ? 1 : 0,
      'notification': habitData.notification ? 1 : 0,
      'notTime': '${habitData.notTime.hour}:${habitData.notTime.minute}',
      'sanction': habitData.sanction,
      'showSanction': habitData.showSanction ? 1 : 0,
      'accountant': habitData.accountant,
      'habitType': habitData.habitType.index,
      'targetValue': habitData.targetValue,
      'partialValue': habitData.partialValue,
      'unit': habitData.unit,
      'questions': jsonEncode(habitData.questions),
      'meterMin': habitData.meterMin,
      'meterMax': habitData.meterMax,
      'meterLabels': jsonEncode(habitData.meterLabels),
      'archived': habitData.archived ? 1 : 0,
      'is24Hour': habitData.is24Hour ? 1 : 0,
      'createdAt': habitData.createdAt.toIso8601String(),
      'color': habitData.color,
      'reminders': jsonEncode(habitData.reminders.map((e) => '${e.hour}:${e.minute}').toList()),
      'isSecret': habitData.isSecret ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': habitData.id,
      'title': habitData.title,
      'twoDayRule': habitData.twoDayRule ? 1 : 0,
      'position': habitData.position,
      'cue': habitData.cue,
      'routine': habitData.routine,
      'reward': habitData.reward,
      'showReward': habitData.showReward ? 1 : 0,
      'advanced': habitData.advanced ? 1 : 0,
      'notification': habitData.notification ? 1 : 0,
      'notTime': '${habitData.notTime.hour}:${habitData.notTime.minute}',
      'events': habitData.events.map((key, value) {
        return MapEntry(
            key.toString(),
            value.length > 2
                ? [value[0].toString(), value[1], value[2]]
                : [value[0].toString(), value[1]]);
      }),
      'sanction': habitData.sanction,
      'showSanction': habitData.showSanction ? 1 : 0,
      'accountant': habitData.accountant,
      'habitType': habitData.habitType.index,
      'targetValue': habitData.targetValue,
      'partialValue': habitData.partialValue,
      'unit': habitData.unit,
      'categories':
          habitData.categories.map((category) => category.toJson()).toList(),
      'questions': habitData.questions,
      'meterMin': habitData.meterMin,
      'meterMax': habitData.meterMax,
      'meterLabels': habitData.meterLabels,
      'archived': habitData.archived ? 1 : 0,
      'is24Hour': habitData.is24Hour ? 1 : 0,
      'createdAt': habitData.createdAt.toIso8601String(),
      'color': habitData.color,
      'reminders': habitData.reminders.map((e) => '${e.hour}:${e.minute}').toList(),
      'isSecret': habitData.isSecret ? 1 : 0,
    };
  }

  Habit.fromJson(Map<String, dynamic> json, {super.key})
      : habitData = HabitData(
          id: json['id'],
          position: json['position'],
          title: json['title'],
          twoDayRule: json['twoDayRule'] != 0 ? true : false,
          cue: json['cue'],
          routine: json['routine'],
          reward: json['reward'],
          showReward: json['showReward'] != 0 ? true : false,
          advanced: json['advanced'] != 0 ? true : false,
          notification: json['notification'] != 0 ? true : false,
          notTime: parseTimeOfDay(json['notTime']),
          events: doEvents(json['events']),
          sanction: json['sanction'] ?? '',
          showSanction: (json['showSanction'] ?? 0) != 0 ? true : false,
          accountant: json['accountant'] ?? '',
          habitType: HabitType.values[json['habitType'] ?? 0],
          targetValue: (json['targetValue'] ?? 1.0).toDouble(),
          partialValue: (json['partialValue'] ?? 1.0).toDouble(),
          unit: json['unit'] ?? '',
          categories: json['categories'] != null
              ? (json['categories'] as List)
                  .map((categoryJson) => Category.fromJson(categoryJson))
                  .toList()
              : [],
          questions: json['questions'] != null
              ? List<String>.from(json['questions'])
              : [],
          meterMin: (json['meterMin'] ?? 0.0).toDouble(),
          meterMax: (json['meterMax'] ?? 10.0).toDouble(),
          meterLabels: json['meterLabels'] != null
              ? List<String>.from(json['meterLabels'])
              : [],
          archived: (json['archived'] ?? 0) != 0 ? true : false,
          is24Hour: (json['is24Hour'] ?? 0) != 0 ? true : false,
          createdAt: json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
          color: json['color'] ?? 0,
          reminders: json['reminders'] != null
              ? (json['reminders'] is List) 
                 ? (json['reminders'] as List).map((e) => parseTimeOfDay(e)).toList()
                 : (jsonDecode(json['reminders']) as List).map((e) => parseTimeOfDay(e)).toList()
              : [],
          isSecret: (json['isSecret'] ?? 0) != 0 ? true : false,
        );

  static SplayTreeMap<DateTime, List> doEvents(Map<String, dynamic> input) {
    SplayTreeMap<DateTime, List> result = SplayTreeMap<DateTime, List>();

    input.forEach((key, value) {
      final dayType = DayType.values
          .firstWhere((e) => e.toString() == reformatOld(value[0]));
      final comment = value[1];

      // Handle progress/meter data for numeric and meter habits
      if (value.length > 2 && (dayType == DayType.progress || dayType == DayType.meter)) {
        final progressValue = (value[2] as num?)?.toDouble() ?? 0.0;
        result[DateTime.parse(key)] = [dayType, comment, progressValue];
      } else {
        result[DateTime.parse(key)] = [dayType, comment];
      }
    });
    return result;
  }

  // To be compatible with older version backup
  static String reformatOld(String value) {
    var all = value.split('.');
    return '${all[0]}.${all[1].toLowerCase()}';
  }

  void navigateToEditPage(BuildContext context) {
    Provider.of<AppStateManager>(context, listen: false).goEditHabit(habitData);
  }

  @override
  State<Habit> createState() => HabitState();
}

class HabitState extends State<Habit> {
  bool _orangeStreak = false;
  bool _streakVisible = false;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _showMonth = false;
  String _actualMonth = '';
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void refresh() {
    setState(() {
      _updateLastStreak();
    });
  }

  @override
  void initState() {
    super.initState();
    _updateLastStreak();
  }

  @override
  void dispose() {
    super.dispose();
  }

  SplayTreeMap<DateTime, List> get events {
    return widget.habitData.events;
  }

  void showRewardNotification(DateTime date) {
    if (isSameDay(date, DateTime.now()) &&
        widget.habitData.showReward &&
        widget.habitData.reward != '') {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Text(
            '${S.of(context).congratulationsReward}\n${widget.habitData.reward}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showSanctionNotification(DateTime date) {
    if (isSameDay(date, DateTime.now()) &&
        widget.habitData.showSanction &&
        widget.habitData.sanction != '') {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Text(
            '${S.of(context).ohNoSanction}\n${widget.habitData.sanction}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor:
              Provider.of<SettingsManager>(context, listen: false).failColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List _getEventsForDay(DateTime day) {
    return widget.habitData.events[transformDate(day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setSelectedDay(selectedDay);
  }

  void setSelectedDay(DateTime selectedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = selectedDay;
        reloadMonth(selectedDay);
      });
    }
  }

  void reloadMonth(DateTime selectedDay) {
    _showMonth = (_calendarFormat == CalendarFormat.month);
    _actualMonth = DateFormat('yMMMM', Intl.getCurrentLocale())
        .format(selectedDay)
        .capitalize();
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
        reloadMonth(_selectedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            HabitHeader(
              widget: widget,
              streakVisible: _streakVisible,
              orangeStreak: _orangeStreak,
              streak: widget.habitData.streak,
            ),
            if (_showMonth &&
                Provider.of<SettingsManager>(context).getShowMonthName)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(_actualMonth),
              ),
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime.now(),
              headerVisible: false,
              currentDay: DateTime.now(),
              availableCalendarFormats: {
                CalendarFormat.month: S.of(context).month,
                CalendarFormat.week: S.of(context).week,
              },
              eventLoader: _getEventsForDay,
              calendarFormat: _calendarFormat,
              daysOfWeekVisible: false,
              onFormatChanged: _onFormatChanged,
              onPageChanged: setSelectedDay,
              onDaySelected: _onDaySelected,
              startingDayOfWeek:
                  Provider.of<SettingsManager>(context).getWeekStartEnum,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  return OneDayButton(
                    callback: refresh,
                    parent: this,
                    id: widget.habitData.id!,
                    date: date,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    event: widget.habitData.events[transformDate(date)],
                  );
                },
                todayBuilder: (context, date, _) {
                  return OneDayButton(
                    callback: refresh,
                    parent: this,
                    id: widget.habitData.id!,
                    date: date,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    event: widget.habitData.events[transformDate(date)],
                  );
                },
                disabledBuilder: (context, date, _) {
                  return OneDay(
                    date: date,
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                          color: (date.weekday > 5) ? Colors.red[300] : null),
                    ),
                  );
                },
                outsideBuilder: (context, date, _) {
                  return OneDay(
                    date: date,
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                          color: (date.weekday > 5) ? Colors.red[300] : null),
                    ),
                  );
                },
                markerBuilder: (context, date, events) {
                  // For savings habits, always show the marker (with carry-forward)
                  if (widget.habitData.isSavings) {
                    return AspectRatio(
                      aspectRatio: 1,
                      child: IgnorePointer(
                        child: _buildSavingsMarker(date, events),
                      ),
                    );
                  }
                  
                  if (events.isNotEmpty) {
                    return _buildEventsMarker(date, events);
                  } else {
                    return null;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AspectRatio(
      aspectRatio: 1,
      child: IgnorePointer(
        child: Stack(children: [
          (events[0] != DayType.clear)
              ? (events[0] == DayType.meter)
                  ? _buildMeterMarker(date, events)
                  : (events[0] == DayType.savings)
                      ? _buildSavingsMarker(date, events)
                      : (events[0] == DayType.check && widget.habitData.isDiary)
                          ? _buildDiaryMarker(date, events)
                          : Container(
                          margin: const EdgeInsets.all(4.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _getEventColor(events),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: _getEventIcon(events),
                        )
              : Container(),
          (events[1] != null && events[1] != '')
              ? Container(
                  alignment: const Alignment(1.0, 1.0),
                  padding: const EdgeInsets.fromLTRB(0, 0, 5.0, 2.0),
                  child: Material(
                    borderRadius: BorderRadius.circular(15.0),
                    elevation: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: HaboColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              : Container(),
        ]),
      ),
    );
  }

  Color _getEventColor(List events) {
    final eventType = events[0] as DayType;

    switch (eventType) {
      case DayType.check:
        final defaultColor = Provider.of<SettingsManager>(context, listen: false).checkColor;
        return HaboColors.getHabitColor(widget.habitData.color, defaultColor);
      case DayType.fail:
        return Provider.of<SettingsManager>(context, listen: false).failColor;
      case DayType.skip:
        return Provider.of<SettingsManager>(context, listen: false).skipColor;
      case DayType.progress:
        // For progress events, check if it's 100% completion
        if (widget.habitData.isNumeric && events.length > 2) {
          final progressValue = (events[2] as num?)?.toDouble() ?? 0.0;
          if (progressValue >= widget.habitData.targetValue) {
            // 100% or more = green check color
            final defaultColor = Provider.of<SettingsManager>(context, listen: false).checkColor;
            return HaboColors.getHabitColor(widget.habitData.color, defaultColor);
          }
        }
        return Provider.of<SettingsManager>(context, listen: false)
            .progressColor;
      case DayType.clear:
        return Colors.transparent;
      case DayType.meter:
        final defaultColor = Provider.of<SettingsManager>(context, listen: false).checkColor;
        return HaboColors.getHabitColor(widget.habitData.color, defaultColor);
      case DayType.savings:
        return Colors.amber;
    }
  }

  Widget _getEventIcon(List events) {
    final eventType = events[0] as DayType;

    switch (eventType) {
      case DayType.check:
        if (widget.habitData.isDiary) {
           return const Icon(
            Icons.book,
            color: Colors.white,
          );
        }
        return const Icon(
          Icons.check,
          color: Colors.white,
        );
      case DayType.fail:
        return const Icon(
          Icons.close,
          color: Colors.white,
        );
      case DayType.skip:
        return const Icon(
          Icons.last_page,
          color: Colors.white,
        );
      case DayType.progress:
        // For progress events, check if it's 100% completion
        if (widget.habitData.isNumeric && events.length > 2) {
          final progressValue = (events[2] as num?)?.toDouble() ?? 0.0;
          if (progressValue >= widget.habitData.targetValue) {
            // 100% or more = green check icon
            return const Icon(
              Icons.check,
              color: Colors.white,
            );
          }
        }
        return _buildProgressIcon(events);
      case DayType.clear:
        return Container();
      case DayType.meter:
        return _buildMeterIcon(events);
      case DayType.savings:
        return _buildSavingsIcon(events);
    }
  }

  Widget _buildProgressIcon(List events) {
    // For progress events, show a circular progress indicator
    if (events.length > 2 && widget.habitData.isNumeric) {
      final progressValue = (events[2] as num?)?.toDouble() ?? 0.0;
      final percentage =
          (progressValue / widget.habitData.targetValue).clamp(0.0, 1.0);

      return Stack(
        children: [
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          Center(
            child: Text(
              '${(percentage * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
    // Fallback for non-numeric progress events
    return const Icon(
      Icons.trending_up,
      color: Colors.white,
      size: 20,
    );
  }

  Widget _buildMeterIcon(List events) {
    if (events.length > 2 && widget.habitData.isMeter) {
      final value = (events[2] as num?)?.toDouble() ?? 0.0;
      return Center(
        child: Text(
          '${value.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    return const Icon(
      Icons.speed,
      color: Colors.white,
    );
  }

  Widget _buildMeterMarker(DateTime date, List events) {
    final value =
        (events.length > 2) ? (events[2] as num?)?.toDouble() ?? 0.0 : 0.0;
    final range = widget.habitData.meterMax - widget.habitData.meterMin;
    final percentage =
        (range > 0) ? ((value - widget.habitData.meterMin) / range).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: _getEventColor(events).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9.0), // Slightly smaller than container to hide edges
        child: Stack(
          children: [
            // Filling background (vertical progress)
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: percentage,
                widthFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getEventColor(events),
                  ),
                ),
              ),
            ),
            // The icon/text
            Center(
              child: _buildMeterIcon(events),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsIcon(List events) {
    if (events.length > 2 && widget.habitData.isSavings) {
      final value = (events[2] as num?)?.toDouble() ?? 0.0;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.savings, size: 14, color: Colors.white),
          Text(
            '₹${value.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
    return const Icon(
      Icons.savings,
      color: Colors.white,
      size: 18,
    );
  }

  Widget _buildSavingsMarker(DateTime date, List events) {
    // Get the actual balance for this date (carry forward if needed)
    double value = widget.habitData.meterMin;
    
    if (events.length > 2 && events[0] == DayType.savings) {
      value = (events[2] as num?)?.toDouble() ?? widget.habitData.meterMin;
    } else {
      // Look backward for the most recent balance
      final sortedDates = widget.habitData.events.keys
          .where((d) => d.isBefore(date) || d.isAtSameMomentAs(date))
          .toList()
        ..sort((a, b) => b.compareTo(a));
      
      for (final d in sortedDates) {
        final event = widget.habitData.events[d];
        if (event != null && event[0] == DayType.savings && event.length > 2) {
          value = (event[2] as num?)?.toDouble() ?? widget.habitData.meterMin;
          break;
        }
      }
    }
    
    final range = widget.habitData.meterMax - widget.habitData.meterMin;
    final percentage =
        (range > 0) ? ((value - widget.habitData.meterMin) / range).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.amber.shade700.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9.0),
        child: Stack(
          children: [
            // Filling background (vertical progress) - Gold color
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: percentage,
                widthFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade700, Colors.orange.shade600],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
            // The icon showing current value
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.savings, size: 14, color: Colors.white),
                  if (value > 0)
                    Text(
                      '₹${value.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryMarker(DateTime date, List events) {
    // Parse the diary data directly from the events
    int filledCount = 0;
    final totalQuestions = widget.habitData.questions.length;

    if (events.length > 1 && events[1] != null && events[1] != '') {
      try {
        final data = events[1] as String;
        final decoded = jsonDecode(data);

        if (decoded is Map<String, dynamic>) {
          // Count how many questions have non-empty answers
          for (var question in widget.habitData.questions) {
            final answer = decoded[question];
            if (answer != null && answer.toString().trim().isNotEmpty) {
              filledCount++;
            }
          }
        }
      } catch (e) {
        // If parsing fails, consider it partially filled
        filledCount = (totalQuestions / 2).round();
      }
    }

    final fillPercentage = totalQuestions > 0 ? filledCount / totalQuestions : 0.0;

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: _getEventColor(events).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9.0),
        child: Stack(
          children: [
            // Filling background (vertical progress)
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: fillPercentage,
                widthFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getEventColor(events),
                  ),
                ),
              ),
            ),
            // The icon/text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book, size: 14, color: Colors.white),
                  if (totalQuestions > 0)
                    Text(
                      '$filledCount/$totalQuestions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateLastStreak() {
    if (widget.habitData.twoDayRule == true) {
      _updateLastStreakTwoDay();
    } else {
      _updateLastStreakNormal();
    }
  }

  void _updateLastStreakNormal() {
    int inStreak = 0;
    var checkDayKey = widget.habitData.events.lastKey();
    var lastDayKey = widget.habitData.events.lastKey();

    while (widget.habitData.events[checkDayKey] != null &&
        widget.habitData.events[checkDayKey]![0] != DayType.fail) {
      if (widget.habitData.events[checkDayKey]![0] != DayType.clear) {
        if (widget.habitData.events[lastDayKey]![0] != null &&
            widget.habitData.events[lastDayKey]![0] != DayType.clear &&
            lastDayKey!.difference(checkDayKey!).inDays > 1) {
          break;
        }
        lastDayKey = checkDayKey;
      }

      if (widget.habitData.events[checkDayKey]![0] == DayType.check ||
          (widget.habitData.events[checkDayKey]![0] == DayType.progress &&
              widget.habitData.events[checkDayKey]![2] >=
                  widget.habitData.targetValue)) {
        inStreak++;
      }
      checkDayKey = widget.habitData.events.lastKeyBefore(checkDayKey!);
    }

    _streakVisible = (inStreak >= 2);

    widget.habitData.streak = inStreak;
  }

  void _updateLastStreakTwoDay() {
    int inStreak = 0;
    var trueLastKey = widget.habitData.events.lastKey();

    // Skip clear entries and single incomplete progress (treated as clear)
    while (widget.habitData.events[trueLastKey] != null &&
        widget.habitData.events[trueLastKey]![0] != null &&
        (widget.habitData.events[trueLastKey]![0] == DayType.clear ||
            (widget.habitData.events[trueLastKey]![0] == DayType.progress &&
                widget.habitData.events[trueLastKey]![2] <
                    widget.habitData.targetValue))) {
      trueLastKey = widget.habitData.events.lastKeyBefore(trueLastKey!);
    }

    var checkDayKey = trueLastKey;
    var lastDayKey = trueLastKey;
    DayType lastDay = DayType.check;

    while (widget.habitData.events[checkDayKey] != null) {
      if (widget.habitData.events[checkDayKey]![0] != DayType.clear) {
        // End if fail and next is not check, clear or progress
        if (widget.habitData.events[checkDayKey]![0] == DayType.fail &&
            (lastDay != DayType.check &&
                lastDay != DayType.clear &&
                (lastDay != DayType.progress))) {
          break;
        }

        // End if gap is more than 1 day
        if (widget.habitData.events[lastDayKey]![0] != null &&
            widget.habitData.events[lastDayKey]![0] != DayType.clear &&
            lastDayKey!.difference(checkDayKey!).inDays > 1) {
          break;
        }

        lastDayKey = checkDayKey;
      }

      // Count streak if check or 100% progress
      lastDay = widget.habitData.events[checkDayKey]![0];
      if (widget.habitData.events[checkDayKey]![0] == DayType.check ||
          (widget.habitData.events[checkDayKey]![0] == DayType.progress &&
              widget.habitData.events[checkDayKey]![2] >=
                  widget.habitData.targetValue)) {
        inStreak++;
      }
      checkDayKey = widget.habitData.events.lastKeyBefore(checkDayKey!);
    }

    _streakVisible = (inStreak >= 2);

    // Set orange streak if last event is fail
    widget.habitData.streak = inStreak;
    _orangeStreak = (widget.habitData.events[trueLastKey] != null &&
        widget.habitData.events[trueLastKey]![0] == DayType.fail);
  }
}
