import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bybit_card_tracker/presentation/providers/filter_provider.dart';

class PeriodPicker extends ConsumerStatefulWidget {
  const PeriodPicker({super.key});

  @override
  ConsumerState<PeriodPicker> createState() => _PeriodPickerState();
}

class _PeriodPickerState extends ConsumerState<PeriodPicker> {
  late ScrollController _scrollController;
  late List<DatePeriod> _months;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _months = _generateMonths();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DatePeriod> _generateMonths() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      final start = DateTime(date.year, date.month, 1);
      final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
      final isCurrentMonth = index == 0;
      return DatePeriod(
        start: start,
        end: end,
        label: isCurrentMonth ? 'Current Month' : DateFormat('MMM yyyy').format(date),
      );
    }).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _months.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: ActionChip(
                label: const Text('Custom'),
                avatar: const Icon(Icons.date_range, size: 16),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (range != null) {
                    ref.read(selectedPeriodProvider.notifier).state = DatePeriod(
                      start: range.start,
                      end: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
                      label: '${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM').format(range.end)}',
                    );
                  }
                },
              ),
            );
          }
          final period = _months[index - 1];
          final isSelected = selectedPeriod == period;
          
          return Padding(
            padding: EdgeInsets.only(right: index == _months.length ? 16 : 8),
            child: ChoiceChip(
              label: Text(period.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(selectedPeriodProvider.notifier).state = period;
                }
              },
            ),
          );
        },
      ),
    );
  }
}
