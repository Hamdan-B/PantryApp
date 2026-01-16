import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pantry_app/presentation/providers/analytics_provider.dart';
import 'package:pantry_app/presentation/providers/pantry_provider.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    final timeRange = ref.watch(analyticsTimeRangeProvider);
    final usageByCategoryData = ref.watch(usageByCategory);
    final totalSpendingAsync = ref.watch(totalSpending);
    final totalWeightAsync = ref.watch(totalWeightUsed);
    final pantryItemsAsync = ref.watch(pantryItemsProvider);
    final usageLogsAsync = ref.watch(usageLogsProvider);
    final spendingOverTimeAsync = ref.watch(spendingOverTime);
    final usageByItemAsync = ref.watch(usageByItem);
    final usedItemNamesAsync = ref.watch(usedItemNames);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Range Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(analyticsTimeRangeProvider.notifier)
                                  .state = 'Last 7 days';
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: timeRange == 'Last 7 days'
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                            ),
                            child: Text(
                              '7 Days',
                              style: TextStyle(
                                color: timeRange == 'Last 7 days'
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(analyticsTimeRangeProvider.notifier)
                                  .state = 'Last 30 days';
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: timeRange == 'Last 30 days'
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                            ),
                            child: Text(
                              '30 Days',
                              style: TextStyle(
                                color: timeRange == 'Last 30 days'
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary Cards Row 1
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.inventory,
                              color: Colors.blue, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Total Items',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          pantryItemsAsync.when(
                            data: (items) => Text(
                              items.length.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('--'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.attach_money,
                              color: Colors.green, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Total Value',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          pantryItemsAsync.when(
                            data: (items) {
                              final total = items.fold<double>(
                                  0.0, (sum, item) => sum + item.price);
                              return Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              );
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('--'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary Cards Row 2
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.remove_shopping_cart,
                              color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Items Used',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          usageLogsAsync.when(
                            data: (logs) => Text(
                              logs.length.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('--'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.trending_up,
                              color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Total Spent',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          totalSpendingAsync.when(
                            data: (total) => Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('--'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),

            // Spending Over Time Chart
            const Text(
              'Spending Over Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            spendingOverTimeAsync.when(
              data: (spending) {
                if (spending.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No spending data available'),
                      ),
                    ),
                  );
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '\$${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < spending.length) {
                                    final date = spending[value.toInt()].key;
                                    return Text(
                                      DateFormat('M/d').format(date),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          minY: 0,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spending
                                  .asMap()
                                  .entries
                                  .map((entry) => FlSpot(
                                      entry.key.toDouble(), entry.value.value))
                                  .toList(),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('Error: $err')),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Total Weight Used Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Weight Used',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    totalWeightAsync.when(
                      data: (total) => Text(
                        '${total.toStringAsFixed(2)} g/ml',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Usage by Category
            const Text(
              'Usage by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            usageByCategoryData.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No usage data available'),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sections: data.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final category = entry.value.key;
                            final value = entry.value.value;
                            final colors = [
                              Colors.red,
                              Colors.blue,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                              Colors.yellow,
                              Colors.pink,
                            ];
                            return PieChartSectionData(
                              value: value,
                              color: colors[index % colors.length],
                              title: category.length > 8
                                  ? '${category.substring(0, 8)}...'
                                  : category,
                              radius: 100,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 24),

            // Per-Item Usage Chart
            const Text(
              'Item Usage Over Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            usedItemNamesAsync.when(
              data: (itemNames) {
                if (itemNames.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No item usage data available'),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButton<String>(
                          value: selectedItem ?? itemNames.first,
                          hint: const Text('Select an item'),
                          isExpanded: true,
                          items: itemNames
                              .map((name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedItem = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ItemUsageChart(itemName: selectedItem ?? itemNames.first),
                  ],
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('Error: $err')),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Usage by Item Bar Chart
            const Text(
              'Total Usage by Item',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            usageByItemAsync.when(
              data: (itemData) {
                if (itemData.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No item usage data available'),
                      ),
                    ),
                  );
                }

                final sortedItems = itemData.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topItems = sortedItems.take(10).toList();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: topItems.first.value * 1.2,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < topItems.length) {
                                    final item = topItems[value.toInt()].key;
                                    return RotatedBox(
                                      quarterTurns: -1,
                                      child: Text(
                                        item.length > 10
                                            ? '${item.substring(0, 10)}...'
                                            : item,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          barGroups: topItems.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value,
                                  color: Colors.blue,
                                  width: 20,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for showing individual item usage over time
class _ItemUsageChart extends ConsumerWidget {
  final String itemName;

  const _ItemUsageChart({required this.itemName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemUsageAsync = ref.watch(itemUsageOverTime(itemName));

    return itemUsageAsync.when(
      data: (usage) {
        if (usage.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No usage data for this item'),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < usage.length) {
                            final date = usage[value.toInt()].key;
                            return Text(
                              DateFormat('M/d').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: usage
                          .asMap()
                          .entries
                          .map((entry) =>
                              FlSpot(entry.key.toDouble(), entry.value.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
