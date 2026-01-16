import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/data/models/planner_meal_model.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/data/datasources/supabase_database_service.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final plannedMealsProvider =
    FutureProvider.family<List<PlannerMealModel>, DateTime>((ref, date) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (authState) async {
      final user = authState.session?.user;
      if (user == null) {
        return [];
      }
      final userId = user.id;
      final db = ref.watch(databaseServiceProvider);
      final meals = await db.getPlannedMealsForDate(userId, date);
      return meals.map((meal) => PlannerMealModel.fromJson(meal)).toList();
    },
    error: (err, stack) => throw err,
    loading: () => throw Exception('Loading'),
  );
});

final currentDatePlannedMealsProvider =
    FutureProvider<List<PlannerMealModel>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(plannedMealsProvider(selectedDate).future);
});

// Planner notifier
class PlannerNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseDatabaseService dbService;
  final Ref ref;

  PlannerNotifier({
    required this.dbService,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<void> addMeal(PlannerMealModel meal) async {
    state = const AsyncValue.loading();
    try {
      print('PlannerNotifier: Adding meal for date ${meal.date}');
      await dbService.addPlannedMeal(meal.toJson());
      print('PlannerNotifier: Meal added, invalidating providers');
      // Invalidate the specific date provider
      ref.invalidate(plannedMealsProvider(meal.date));
      ref.invalidate(selectedDateProvider);
      ref.invalidate(currentDatePlannedMealsProvider);
      state = const AsyncValue.data(null);
      print('PlannerNotifier: Providers invalidated successfully');
    } catch (e, stack) {
      print('PlannerNotifier: Error adding meal: $e');
      print('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteMeal(String mealId) async {
    state = const AsyncValue.loading();
    try {
      await dbService.deletePlannedMeal(mealId);
      ref.invalidate(currentDatePlannedMealsProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final plannerNotifierProvider =
    StateNotifierProvider<PlannerNotifier, AsyncValue<void>>((ref) {
  return PlannerNotifier(
    dbService: ref.watch(databaseServiceProvider),
    ref: ref,
  );
});
