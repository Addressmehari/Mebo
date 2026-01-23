import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/statistics/statistics.dart';
import 'package:intl/intl.dart';

class TrendLineChart extends StatefulWidget {
  final StatisticsData data;

  const TrendLineChart({super.key, required this.data});

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    if (widget.data.valueHistory.isNotEmpty) {
      // Find the latest year with data
      year = widget.data.valueHistory.keys
          .map((e) => e.year)
          .reduce((value, element) => value > element ? value : element);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Year Selector Header
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                items: _getAvailableYears().map((int value) {
                  return DropdownMenuItem<String>(
                    value: value.toString(),
                    child: Text(
                      value.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                value: year.toString(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      year = int.parse(value);
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Chart Area
        SizedBox(
          height: 200,
          child: _buildChart(),
        ),
        const SizedBox(height: 16),
        // Statistics Summary for the selected year
        _buildSummary(),
      ],
    );
  }

  List<int> _getAvailableYears() {
    final years = widget.data.valueHistory.keys.map((e) => e.year).toSet().toList();
    if (years.isEmpty) return [DateTime.now().year];
    years.sort();
    return years;
  }

  Widget _buildSummary() {
    final points = _getPointsForYear();
    if (points.isEmpty) return const SizedBox.shrink();

    double total = 0;
    double max = 0;
    
    for (var p in points) {
      total += p.y;
      if (p.y > max) max = p.y;
    }

    // Special logic for Money/Savings to show balance growth instead of raw sum if needed
    // But currently we decided valueHistory stores the absolute value/balance at that time.
    
    double avg = total / points.length;
    final lastValue = points.last.y;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoColumn(
          context, 
          'Total', 
          _formatValue(total), 
          Icons.functions
        ),
        _buildInfoColumn(
          context, 
          'Average', 
          _formatValue(avg), 
          Icons.analytics
        ),
        _buildInfoColumn(
          context, 
          'Max', 
          _formatValue(max), 
          Icons.arrow_upward
        ),
      ],
    );
  }

  String _formatValue(double val) {
    if (widget.data.habitType == HabitType.savings) {
      return '₹${val.toStringAsFixed(0)}';
    }
    return '${val.toStringAsFixed(1)} ${widget.data.unit}';
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
             Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
             const SizedBox(width: 4),
             Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChart() {
    final points = _getPointsForYear();
    if (points.isEmpty) {
      return const Center(child: Text("No data for this year"));
    }

    // Determine colors based on habit type
    List<Color> gradientColors = [
      HaboColors.progress,
      HaboColors.progress.withOpacity(0.5),
    ];
    
    if (widget.data.habitType == HabitType.savings) {
      gradientColors = [
        Colors.amber,
        Colors.amber.withOpacity(0.5),
      ];
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(points),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 30, // Approx one month
              getTitlesWidget: (value, meta) {
                final date = DateTime(year, 1, 1).add(Duration(days: value.toInt()));
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat.MMM().format(date), 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y axis labels for cleaner look, use tooltip
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 366,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            gradient: LinearGradient(colors: gradientColors),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: gradientColors.map((color) => color.withOpacity(0.2)).toList(),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             getTooltipColor: (touchedSpot) => Theme.of(context).cardColor,
             getTooltipItems: (touchedSpots) {
               return touchedSpots.map((LineBarSpot touchedSpot) {
                 final date = DateTime(year, 1, 1).add(Duration(days: touchedSpot.x.toInt()));
                 final valString = _formatValue(touchedSpot.y);
                 return LineTooltipItem(
                   '${DateFormat.MMMd().format(date)}\n$valString',
                   TextStyle(
                     color: Theme.of(context).textTheme.bodyLarge?.color,
                     fontWeight: FontWeight.bold,
                   ),
                 );
               }).toList();
             },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(List<FlSpot> points) {
    if (points.isEmpty) return 10;
    double maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) return 10;
    return maxY / 4;
  }

  List<FlSpot> _getPointsForYear() {
    final entries = widget.data.valueHistory.entries
        .where((e) => e.key.year == year)
        .toList();
        
    if (entries.isEmpty) return [];

    entries.sort((a, b) => a.key.compareTo(b.key));
    
    // Convert date to Day of Year (0-365)
    return entries.map((e) {
      final dayOfYear = int.parse(DateFormat("D").format(e.key));
      return FlSpot(dayOfYear.toDouble(), e.value);
    }).toList();
  }
}
