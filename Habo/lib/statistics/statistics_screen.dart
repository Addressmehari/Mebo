
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/generated/l10n.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:habo/navigation/routes.dart';
import 'package:habo/statistics/empty_statistics_image.dart';
import 'package:habo/statistics/overall_statistics_card.dart';
import 'package:habo/statistics/statistics.dart';
import 'package:habo/statistics/statistics_card.dart';
import 'package:habo/navigation/app_state_manager.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  static MaterialPage page() {
    return MaterialPage(
      name: Routes.statisticsPath,
      key: ValueKey(Routes.statisticsPath),
      child: const StatisticsScreen(),
    );
  }

  const StatisticsScreen({
    super.key,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Provider.of<AppStateManager>(context, listen: false)
              .goStatistics(false);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              S.of(context).statistics,
            ),
            backgroundColor: Colors.transparent,
            iconTheme: Theme.of(context).iconTheme,
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Consistency'),
                Tab(text: 'Metrics'),
                Tab(text: 'Finance'),
              ],
            ),
          ),
          body: FutureBuilder(
              future: Provider.of<HabitsManager>(context).getFutureStatsData(),
              builder:
                  (BuildContext context, AsyncSnapshot<AllStatistics> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.habitsData.isEmpty) {
                    return const EmptyStatisticsImage();
                  } else {
                    // Categorize data
                    final consistencyHabits = snapshot.data!.habitsData.where((h) => 
                      h.habitType == HabitType.boolean || h.habitType == HabitType.diary).toList();
                      
                    final metricHabits = snapshot.data!.habitsData.where((h) => 
                      h.habitType == HabitType.numeric || h.habitType == HabitType.meter).toList();
                      
                    final financeHabits = snapshot.data!.habitsData.where((h) => 
                      h.habitType == HabitType.savings).toList();

                    return TabBarView(
                      children: [
                        // Tab 1: Overview
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: OverallStatisticsCard(
                            total: snapshot.data!.total,
                            habits: snapshot.data!.habitsData.length,
                          ),
                        ),
                        
                        // Tab 2: Consistency (Boolean & Diary)
                        _buildHabitList(consistencyHabits, "No regular habits found"),
                        
                        // Tab 3: Metrics (Numeric & Meter)
                        _buildHabitList(metricHabits, "No metric habits found"),
                        
                        // Tab 4: Finance (Savings)
                        _buildHabitList(financeHabits, "No finance habits found"),
                      ],
                    );
                  }
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: HaboColors.primary,
                    ),
                  );
                }
              }),
        ),
      ),
    );
  }

  Widget _buildHabitList(List<StatisticsData> habits, String emptyMessage) {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Theme.of(context).disabledColor)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: StatisticsCard(data: habits[index]),
        );
      },
    );
  }
}
