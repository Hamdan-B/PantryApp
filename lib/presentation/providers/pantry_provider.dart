import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/data/models/pantry_item_model.dart';
import 'package:pantry_app/data/models/usage_log_model.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/data/datasources/supabase_database_service.dart';

final pantryItemsProvider = FutureProvider<List<PantryItemModel>>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (authState) async {
      final user = authState.session?.user;
      if (user == null) {
        return [];
      }
      final userId = user.id;
      final db = ref.watch(databaseServiceProvider);
      final items = await db.getUserPantryItems(userId);
      return items.map((item) => PantryItemModel.fromJson(item)).toList();
    },
    error: (err, stack) => throw err,
    loading: () => throw Exception('Loading'),
  );
});

// Pantry notifier for mutations
class PantryNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseDatabaseService dbService;
  final String userId;
  final Ref ref;

  PantryNotifier({
    required this.dbService,
    required this.userId,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<void> addItem(PantryItemModel item) async {
    state = const AsyncValue.loading();
    try {
      print('[PANTRY] Adding item: ${item.toJson()}');
      final inserted = await dbService.addPantryItem(item.toJson());
      print('[PANTRY] Item inserted: $inserted');
      print('[PANTRY] Invalidating pantryItemsProvider');
      ref.invalidate(pantryItemsProvider);
      state = const AsyncValue.data(null);
      print('[PANTRY] Add item complete');
    } catch (e, stack) {
      print('[PANTRY] Error adding item: $e');
      print('[PANTRY] Stack: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateItem(PantryItemModel item) async {
    state = const AsyncValue.loading();
    try {
      if (item.id == null) {
        throw Exception('Item ID is null');
      }
      await dbService.updatePantryItem(item.id!, item.toJson());
      ref.invalidate(pantryItemsProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteItem(String itemId) async {
    state = const AsyncValue.loading();
    try {
      await dbService.deletePantryItem(itemId);
      ref.invalidate(pantryItemsProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> removeItemPortion(String itemId, double amountUsed) async {
    state = const AsyncValue.loading();
    try {
      final items = await ref.read(pantryItemsProvider.future);
      final item = items.firstWhere((i) => i.id == itemId);

      // Calculate proportional price
      final remainingWeight = item.weight - amountUsed;
      final pricePerUnit = item.price / item.weight;
      final newPrice = remainingWeight * pricePerUnit;
      final priceUsed = amountUsed * pricePerUnit;

      // Create usage log
      final usageLog = UsageLogModel(
        userId: userId,
        itemId: itemId,
        itemName: item.name,
        category: item.category,
        weightUsed: amountUsed,
        priceUsed: priceUsed,
        unit: item.unit,
        usedAt: DateTime.now(),
      );

      print('[PANTRY] Creating usage log: ${usageLog.toJson()}');
      await dbService.addUsageLog(usageLog.toJson());

      if (remainingWeight <= 0) {
        await deleteItem(itemId);
      } else {
        await updateItem(item.copyWith(
          weight: remainingWeight,
          price: newPrice,
        ));
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      print('[PANTRY] Error removing item portion: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addItemPortion(
      String itemId, double addWeight, double addPrice) async {
    state = const AsyncValue.loading();
    try {
      final items = await ref.read(pantryItemsProvider.future);
      final item = items.firstWhere((i) => i.id == itemId);

      final newWeight = item.weight + addWeight;
      final newPrice = item.price + addPrice;

      await updateItem(item.copyWith(
        weight: newWeight,
        price: newPrice,
      ));

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final pantryNotifierProvider =
    StateNotifierProvider.family<PantryNotifier, AsyncValue<void>, String>(
        (ref, userId) {
  return PantryNotifier(
    dbService: ref.watch(databaseServiceProvider),
    userId: userId,
    ref: ref,
  );
});

// Pantry by category
final pantryByCategoryProvider =
    FutureProvider.family<List<PantryItemModel>, String>(
  (ref, category) async {
    final items = await ref.watch(pantryItemsProvider.future);
    return items.where((item) => item.category == category).toList();
  },
);
