import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';

class DailyBarChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final bool showInUah;
  final double exchangeRate;

  const DailyBarChart({
    super.key,
    required this.data,
    required this.showInUah,
    required this.exchangeRate,
  });

  static const _palette = [
    Color(0xFFF0B90B), // gold
    Color(0xFF00D68F), // green
    Color(0xFF6C5CE7), // purple
    Color(0xFFFF4D6A), // red
    Color(0xFF0984E3), // blue
    Color(0xFFFD79A8), // pink
    Color(0xFFE17055), // orange
    Color(0xFF00CEC9), // teal
    Color(0xFFA29BFE), // lavender
    Color(0xFFFFBE76), // peach
  ];

  List<MapEntry<String, double>> _globalCategoryTotals(
      Map<String, Map<String, double>> data) {
    final totals = <String, double>{};
    for (final dayEntry in data.entries) {
      for (final catEntry in dayEntry.value.entries) {
        totals[catEntry.key] = (totals[catEntry.key] ?? 0) + catEntry.value;
      }
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(7).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        child: Text('No daily data yet', style: theme.textTheme.bodyMedium),
      );
    }

    final entries = data.entries.toList();
    final topCats = _globalCategoryTotals(data);
    final topCatNames = topCats.map((e) => e.key).toList();
    final symbol = showInUah ? '\u20B4' : '\$';

    final dayData = entries.map((dayEntry) {
      final dayCatMap = <String, double>{};
      double otherSum = 0;
      for (final catEntry in dayEntry.value.entries) {
        if (topCatNames.contains(catEntry.key)) {
          dayCatMap[catEntry.key] = catEntry.value;
        } else {
          otherSum += catEntry.value;
        }
      }
      if (otherSum > 0) {
        dayCatMap['Other'] = (dayCatMap['Other'] ?? 0) + otherSum;
      }
      final sortedCats = dayCatMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return MapEntry(dayEntry.key, sortedCats);
    }).toList();

    final maxTotal = dayData.isEmpty
        ? 0.0
        : dayData
            .map((d) =>
                d.value.fold<double>(0, (sum, e) => sum + e.value))
            .reduce(max);

    final hasOther = dayData.any(
        (d) => d.value.any((e) => e.key == 'Other'));
    final legendNames = hasOther && !topCatNames.contains('Other')
        ? [...topCatNames, 'Other']
        : topCatNames;

    final legendTotals = <String, double>{};
    for (final day in dayData) {
      for (final cat in day.value) {
        legendTotals[cat.key] = (legendTotals[cat.key] ?? 0) + cat.value;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Spending',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxTotal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = dayData[group.x.toInt()];
                      final buffer = StringBuffer('${day.key}\n');
                      for (final cat in day.value) {
                        buffer.write(
                            '${cat.key}: $symbol${cat.value.toStringAsFixed(0)}\n');
                      }
                      return BarTooltipItem(
                        buffer.toString().trim(),
                        TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '$symbol${value.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: entries.length <= 60,
                      reservedSize: 30,
                      interval: entries.length > 15 ? 5 : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final key = entries[idx].key;
                        final label = key.split(' ').first;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.cardBorderColor, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dayData.length, (i) {
                  final dayCatList = dayData[i].value;
                  double cumulative = 0;
                  final stackItems = <BarChartRodStackItem>[];

                  for (final cat in dayCatList) {
                    final catIndex = legendNames.indexOf(cat.key);
                    final color = _palette[catIndex % _palette.length];
                    stackItems.add(BarChartRodStackItem(
                      cumulative,
                      cumulative + cat.value,
                      color,
                    ));
                    cumulative += cat.value;
                  }

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: cumulative,
                        fromY: 0,
                        width: dayData.length > 15 ? 6 : 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        color: AppTheme.gold.withValues(alpha: 0.3),
                        rodStackItems: stackItems,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(legendNames.length, (i) {
              final catName = legendNames[i];
              final total = legendTotals[catName] ?? 0;
              final displayTotal =
                  '$symbol${total.toStringAsFixed(0)}';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _palette[i % _palette.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    catName,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayTotal,
                    style: TextStyle(
                      color: _palette[i % _palette.length],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
