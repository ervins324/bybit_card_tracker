import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:bybit_card_tracker/core/theme/app_theme.dart';

/// Interactive pie chart showing expense distribution by category.
class CategoryPieChart extends StatefulWidget {
  /// Category name → amount in USD (absolute).
  final Map<String, double> data;
  final bool showInUah;
  final double exchangeRate;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.showInUah,
    required this.exchangeRate,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  // Curated palette for chart segments
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.data.isEmpty) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        child: Text(
          'No spending data yet',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Collapse categories beyond top 7 into "Other"
    final entries = widget.data.entries.toList();
    final topEntries = entries.take(7).toList();
    final otherSum = entries
        .skip(7)
        .fold<double>(0.0, (sum, e) => sum + e.value);
    if (otherSum > 0) {
      topEntries.add(MapEntry('Other', otherSum));
    }

    final total = topEntries.fold<double>(0.0, (s, e) => s + e.value);

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
            'Spending by Category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = response
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(topEntries.length, (i) {
                        final isTouched = i == _touchedIndex;
                        final entry = topEntries[i];
                        final pct = (entry.value / total) * 100;
                        return PieChartSectionData(
                          value: entry.value,
                          color: _palette[i % _palette.length],
                          radius: isTouched ? 60 : 48,
                          title: isTouched
                              ? '${pct.toStringAsFixed(1)}%'
                              : '',
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        min(topEntries.length, 8),
                        (i) {
                          final entry = topEntries[i];
                          final value = widget.showInUah
                              ? entry.value * widget.exchangeRate
                              : entry.value;
                          final symbol = widget.showInUah ? '₴' : '\$';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _palette[i % _palette.length],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontSize: 11,
                                          color: i == _touchedIndex
                                              ? Colors.white
                                              : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '$symbol${value.toStringAsFixed(0)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontSize: 10,
                                          color: _palette[
                                              i % _palette.length],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
