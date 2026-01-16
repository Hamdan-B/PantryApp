import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/presentation/providers/auth_provider.dart';
import 'package:pantry_app/presentation/providers/pantry_provider.dart';
import 'package:pantry_app/data/models/recipe_model.dart';

final mealSearchProvider =
    FutureProvider.family<List<RecipeModel>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }
  final mealDb = ref.watch(mealDbServiceProvider);
  return mealDb.searchRecipesByName(query);
});

final randomRecipesProvider = FutureProvider<List<RecipeModel>>((ref) async {
  final mealDb = ref.watch(mealDbServiceProvider);
  return mealDb.getRandomRecipes(10);
});

final recipeByIdProvider =
    FutureProvider.family<RecipeModel?, String>((ref, id) async {
  final mealDb = ref.watch(mealDbServiceProvider);
  return mealDb.getRecipeById(id);
});

final recipeByLetterProvider =
    FutureProvider.family<List<RecipeModel>, String>((ref, letter) async {
  if (letter.isEmpty) {
    return [];
  }
  final mealDb = ref.watch(mealDbServiceProvider);
  return mealDb.getRecipesByFirstLetter(letter);
});

// Calculate ingredient match percentage for a recipe
final recipeIngredientMatchProvider =
    FutureProvider.family<double, RecipeModel>((ref, recipe) async {
  try {
    final pantryItems = await ref.watch(pantryItemsProvider.future);
    if (pantryItems.isEmpty || recipe.ingredients.isEmpty) {
      return 0.0;
    }

    // Get all pantry item names (lowercase for comparison)
    final pantryItemNames =
        pantryItems.map((item) => item.name.toLowerCase()).toSet();

    // Count matching ingredients
    int matchingCount = 0;
    for (final ingredient in recipe.ingredients) {
      if (ingredient.isEmpty) continue;
      final ingredientLower = ingredient.toLowerCase().trim();
      // Check for exact match or partial match
      if (pantryItemNames.any((pantryItem) =>
          pantryItem.contains(ingredientLower) ||
          ingredientLower.contains(pantryItem))) {
        matchingCount++;
      }
    }

    // Calculate percentage
    final percentage = (matchingCount / recipe.ingredients.length) * 100;
    return percentage;
  } catch (e) {
    print('[RECIPE_MATCH] Error calculating match: $e');
    return 0.0;
  }
});

// State for pantry matching
class RecipeWithMatchProvider extends StateNotifier<Map<String, double>> {
  RecipeWithMatchProvider() : super({});

  void setMatchPercentage(String recipeId, double percentage) {
    state = {...state, recipeId: percentage};
  }
}

final recipeMatchProvider =
    StateNotifierProvider<RecipeWithMatchProvider, Map<String, double>>((ref) {
  return RecipeWithMatchProvider();
});
