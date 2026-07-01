import 'package:flutter_riverpod/flutter_riverpod.dart';

class DatePeriod {
  final DateTime start;
  final DateTime end;
  final String label;

  const DatePeriod({
    required this.start,
    required this.end,
    required this.label,
  });

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatePeriod &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          label == other.label;

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ label.hashCode;
}

final selectedPeriodProvider = StateProvider<DatePeriod>((ref) {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return DatePeriod(
    start: startOfMonth,
    end: endOfMonth,
    label: 'Current Month',
  );
});
