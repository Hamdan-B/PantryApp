import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/data/models/wishlist_item_model.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/data/datasources/supabase_database_service.dart';

final wishlistItemsProvider =
    FutureProvider<List<WishlistItemModel>>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (authState) async {
      final user = authState.session?.user;
      if (user == null) {
        return [];
      }
      final userId = user.id;
      final db = ref.watch(databaseServiceProvider);
      final items = await db.getWishlistItems(userId);
      return items.map((item) => WishlistItemModel.fromJson(item)).toList();
    },
    error: (err, stack) => throw err,
    loading: () => throw Exception('Loading'),
  );
});

class WishlistNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseDatabaseService dbService;
  final Ref ref;

  WishlistNotifier({
    required this.dbService,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<void> addItem(WishlistItemModel item) async {
    state = const AsyncValue.loading();
    try {
      debugPrint('WishlistNotifier: Adding item ${item.itemName}');
      await dbService.addWishlistItem(item.toJson());
      ref.invalidate(wishlistItemsProvider);
      state = const AsyncValue.data(null);
      debugPrint('WishlistNotifier: Item added successfully');
    } catch (e, stack) {
      debugPrint('WishlistNotifier: Error adding item: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteItem(String itemId) async {
    state = const AsyncValue.loading();
    try {
      debugPrint('WishlistNotifier: Deleting item $itemId');
      await dbService.deleteWishlistItem(itemId);
      ref.invalidate(wishlistItemsProvider);
      state = const AsyncValue.data(null);
      debugPrint('WishlistNotifier: Item deleted successfully');
    } catch (e, stack) {
      debugPrint('WishlistNotifier: Error deleting item: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

final wishlistNotifierProvider =
    StateNotifierProvider<WishlistNotifier, AsyncValue<void>>((ref) {
  return WishlistNotifier(
    dbService: ref.watch(databaseServiceProvider),
    ref: ref,
  );
});
