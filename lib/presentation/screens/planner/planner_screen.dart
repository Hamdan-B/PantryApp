import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/presentation/providers/planner_provider.dart';
import 'package:pantry_app/presentation/screens/planner/day_planner_screen.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final days = <DateTime>[];

    // Add empty days for alignment (start from Monday)
    final firstWeekday = firstDay.weekday;
    for (int i = 1; i < firstWeekday; i++) {
      days.add(firstDay.subtract(Duration(days: firstWeekday - i)));
    }

    // Add all days in the month
    for (int i = 0; i < lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }

    // Add days to complete the last week
    while (days.length % 7 != 0) {
      days.add(lastDay.add(Duration(days: days.length - lastDay.day + 1)));
    }

    return days;
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 32),
                  onPressed: _previousMonth,
                ),
                Text(
                  _getMonthName(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 32),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Weekday Headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final isCurrentMonth = date.month == _selectedMonth.month;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return _CalendarDayCell(
                  date: date,
                  isCurrentMonth: isCurrentMonth,
                  isToday: isToday,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DayPlannerScreen(date: date),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends ConsumerWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(plannedMealsProvider(date));

    return mealsAsync.when(
      data: (meals) {
        final hasMeals = meals.isNotEmpty;

        return InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.blue[100]
                  : hasMeals
                      ? Colors.green[50]
                      : Colors.transparent,
              border: Border.all(
                color: isToday ? Colors.blue : Colors.grey[300]!,
                width: isToday ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentMonth
                        ? (isToday ? Colors.blue : Colors.black)
                        : Colors.grey[400],
                  ),
                ),
                if (hasMeals) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      meals.length.clamp(0, 4),
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isToday ? Colors.blue[100] : Colors.transparent,
            border: Border.all(
              color: isToday ? Colors.blue : Colors.grey[300]!,
              width: isToday ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isCurrentMonth
                    ? (isToday ? Colors.blue : Colors.black)
                    : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                color: isCurrentMonth ? Colors.black : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
