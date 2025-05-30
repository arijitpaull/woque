import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:woke/mood_hive.dart';

class MoodTimelineChart extends StatelessWidget {
  final List<MoodEntry> moodEntries;
  final DateTime weekStartDate; 

  const MoodTimelineChart({
    super.key,
    required this.moodEntries,
    required this.weekStartDate,
  });

  @override
  Widget build(BuildContext context) {
    
    if (moodEntries.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'No mood data recorded yet',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
      );
    }

    
    final moodData = _processMoodData();

    return Container(
      height: 180,
      padding: const EdgeInsets.only(right: 12, top: 12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: false,
          ),
          titlesData: _getTitlesData(context),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                width: 1,
              ),
              left: BorderSide(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          minX: 0,
          maxX: 6, 
          minY: 0,
          maxY: 5, 
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Theme.of(context).colorScheme.primary.withOpacity(0.8),
              tooltipBorder: BorderSide.none,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final date = weekStartDate.add(Duration(days: touchedSpot.x.toInt()));
                  final dateStr = DateFormat('EEE, MMM d').format(date);
                  final moodDescription = _getMoodDescription(touchedSpot.y);
                  
                  return LineTooltipItem(
                    '$dateStr: $moodDescription',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: moodData,
              isCurved: true,
              curveSmoothness: 0.5,
              color: Theme.of(context).colorScheme.secondary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).colorScheme.secondary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodDescription(double value) {
  if (value >= 4.5) return 'Excellent';
  if (value >= 4.0) return 'Very Good';
  if (value >= 3.5) return 'Good';
  if (value >= 3.0) return 'Neutral';
  if (value >= 2.5) return 'Unsettled';
  if (value >= 2.0) return 'Low';
  if (value >= 1.5) return 'Very Low';
  return 'Overwhelmed';
}


  List<FlSpot> _processMoodData() {
  final startOfWeek = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day);
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  final Map<int, double> moodValuesByDay = {};

  const Map<String, double> moodValues = {
    'happy': 5.0,
    'excited': 4.8,
    'peaceful': 4.5,
    'focused': 4.3,
    'content': 4.0,
    'hopeful': 3.8,
    'neutral': 3.0,
    'tired': 2.8,
    'confused': 2.5,
    'overwhelmed': 2.0,
    'anxious': 1.8,
    'sad': 1.5,
    'angry': 1.2,
    'stressed': 1.0,
    'burned out': 0.8,
  };

  for (final entry in moodEntries) {
    final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
    if (entryDate.isBefore(startOfWeek) || entryDate.isAfter(endOfWeek)) continue;

    final dayIndex = entryDate.weekday - 1;

    double totalMoodValue = 0;
    int validMoods = 0;

    for (final mood in entry.moods) {
      final lowerMood = mood.toLowerCase();
      if (moodValues.containsKey(lowerMood)) {
        totalMoodValue += moodValues[lowerMood]!;
        validMoods++;
      }
    }

    final avgMood = validMoods > 0 ? totalMoodValue / validMoods : 3.0;
    moodValuesByDay[dayIndex] = avgMood;
  }

  final List<FlSpot> spots = [];
  for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
    if (moodValuesByDay.containsKey(dayIndex)) {
      spots.add(FlSpot(dayIndex.toDouble(), moodValuesByDay[dayIndex]!));
    }
  }

  return spots;
}


  FlTitlesData _getTitlesData(BuildContext context) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final dayIndex = value.toInt();
            if (dayIndex < 0 || dayIndex > 6) return const SizedBox.shrink();
            
            final date = weekStartDate.add(Duration(days: dayIndex));
            final dayName = DateFormat('EEE').format(date);
            
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                dayName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    interval: 0.5,  
    reservedSize: 40,
    getTitlesWidget: (value, meta) {
      String text;
      switch (value.toStringAsFixed(1)) {
        case '1.0':
          text = 'Bleak';
          break;
        case '2.0':
          text = 'Sad';
          break;
        case '3.0':
          text = 'Okay';
          break;
        case '4.0':
          text = 'Good';
          break;
        case '5.0':
          text = 'Elated';
          break;
        default:
          return const SizedBox.shrink();
      }

      return Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      );
    },
  ),
),

      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }
}