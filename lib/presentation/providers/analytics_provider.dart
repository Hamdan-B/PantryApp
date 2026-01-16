import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/data/models/usage_log_model.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/data/datasources/supabase_database_service.dart';

final analyticsTimeRangeProvider = StateProvider<String>((ref) {
  return 'Last 7 days';
});

final usageLogsProvider = FutureProvider<List<UsageLogModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final timeRange = ref.watch(analyticsTimeRangeProvider);

  return authState.when(
    data: (authState) async {
      final user = authState.session?.user;
      if (user == null) {
        return [];
      }
      final userId = user.id;
      final db = ref.watch(databaseServiceProvider);

      DateTime startDate = DateTime.now();
      switch (timeRange) {
        case 'Last 7 days':
          startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'Last 30 days':
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        default:
          startDate = DateTime.now().subtract(const Duration(days: 7));
      }

      final logs = await db.getUserUsageLogs(
        userId,
        startDate: startDate,
        endDate: DateTime.now(),
      );
      return logs.map((log) => UsageLogModel.fromJson(log)).toList();
    },
    error: (err, stack) => throw err,
    loading: () => throw Exception('Loading'),
  );
});

// Analytics data providers
final usageByCategory = FutureProvider<Map<String, double>>((ref) async {
  final logs = await ref.watch(usageLogsProvider.future);
  final Map<String, double> categoryUsage = {};

  for (final log in logs) {
    categoryUsage[log.category] =
        (categoryUsage[log.category] ?? 0) + log.weightUsed;
  }

  return categoryUsage;
});

final spendingOverTime =
    FutureProvider<List<MapEntry<DateTime, double>>>((ref) async {
  final logs = await ref.watch(usageLogsProvider.future);
  final Map<DateTime, double> spending = {};

  for (final log in logs) {
    final date = DateTime(log.usedAt.year, log.usedAt.month, log.usedAt.day);
    spending[date] = (spending[date] ?? 0) + log.priceUsed;
  }

  final entries = spending.entries.toList();
  entries.sort((a, b) => a.key.compareTo(b.key));
  return entries;
});

final totalSpending = FutureProvider<double>((ref) async {
  final logs = await ref.watch(usageLogsProvider.future);
  return logs.fold<double>(0.0, (sum, log) => sum + log.priceUsed);
});

final totalWeightUsed = FutureProvider<double>((ref) async {
  final logs = await ref.watch(usageLogsProvider.future);
  return logs.fold<double>(0.0, (sum, log) => sum + log.weightUsed);
});

// Per-item usage analytics
final usageByItem = FutureProvider<Map<String, double>>((ref) async {
  final logs = await ref.watch(usageLogsProvider.future);
  final Map<String, double> itemUsage = {};

  for (final log in logs) {
    itemUsage[log.itemName] = (itemUsage[log.itemName] ?? 0) + log.weightUsed;
  }

  return itemUsage;
});

// Item usage over time for a specific item
final itemUsageOverTime =
    FutureProvider.family<List<MapEntry<DateTime, double>>, String>(
  (ref, itemName) async {
    final logs = await ref.watch(usageLogsProvider.future);
    final Map<DateTime, double> usage = {};

    for (final log in logs) {
      if (log.itemName == itemName) {
        final date =
            DateTime(log.usedAt.year, log.usedAt.month, log.usedAt.day);
        usage[date] = (usage[date] ?? 0) + log.weightUsed;
      }
    }

    final entries = usage.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  },
);

// Get list of unique item names from usage logs
final usedItemNames = FutureProvider<List<String>>((ref) async {
  final logs = await ref.watch(usageLogsProvider.future);
  final names = logs.map((log) => log.itemName).toSet().toList();
  names.sort();
  return names;
});

// Usage log notifier
class UsageLogNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseDatabaseService dbService;
  final Ref ref;

  UsageLogNotifier({
    required this.dbService,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<void> addUsageLog(UsageLogModel log) async {
    state = const AsyncValue.loading();
    try {
      await dbService.addUsageLog(log.toJson());
      ref.invalidate(usageLogsProvider);
      ref.invalidate(usageByCategory);
      ref.invalidate(spendingOverTime);
      ref.invalidate(totalSpending);
      ref.invalidate(totalWeightUsed);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final usageLogNotifierProvider =
    StateNotifierProvider<UsageLogNotifier, AsyncValue<void>>((ref) {
  return UsageLogNotifier(
    dbService: ref.watch(databaseServiceProvider),
    ref: ref,
  );
});
