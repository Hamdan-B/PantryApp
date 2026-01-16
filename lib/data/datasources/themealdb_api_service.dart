import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pantry_app/core/constants/app_constants.dart';
import 'package:pantry_app/core/utils/exceptions.dart';
import 'package:pantry_app/data/models/recipe_model.dart';

class TheMealDbService {
  final http.Client client;

  TheMealDbService({http.Client? client}) : client = client ?? http.Client();

  Future<List<RecipeModel>> searchRecipesByName(String name) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.mealDbBaseUrl}/search.php?s=$name'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['meals'] == null) {
          return [];
        }

        final meals = json['meals'] as List<dynamic>;
        return meals
            .map((meal) => RecipeModel.fromJson(meal as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          message: 'Failed to search recipes. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error searching recipes: ${e.toString()}',
      );
    }
  }

  Future<List<RecipeModel>> getRecipesByFirstLetter(String letter) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.mealDbBaseUrl}/search.php?f=$letter'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['meals'] == null) {
          return [];
        }

        final meals = json['meals'] as List<dynamic>;
        return meals
            .map((meal) => RecipeModel.fromJson(meal as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          message: 'Failed to fetch recipes. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error fetching recipes: ${e.toString()}',
      );
    }
  }

  Future<RecipeModel?> getRecipeById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.mealDbBaseUrl}/lookup.php?i=$id'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['meals'] == null || (json['meals'] as List).isEmpty) {
          return null;
        }

        final meal = (json['meals'] as List)[0] as Map<String, dynamic>;
        return RecipeModel.fromJson(meal);
      } else {
        throw ApiException(
          message: 'Failed to fetch recipe. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error fetching recipe: ${e.toString()}',
      );
    }
  }

  Future<List<RecipeModel>> getRandomRecipes(int count) async {
    try {
      final recipes = <RecipeModel>[];
      for (int i = 0; i < count; i++) {
        final response = await client.get(
          Uri.parse('${AppConstants.mealDbBaseUrl}/random.php'),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          if (json['meals'] != null) {
            final meal = (json['meals'] as List)[0] as Map<String, dynamic>;
            recipes.add(RecipeModel.fromJson(meal));
          }
        }
      }
      return recipes;
    } catch (e) {
      throw ApiException(
        message: 'Error fetching random recipes: ${e.toString()}',
      );
    }
  }

  // Helper method to parse ingredients from recipe
  static List<String> parseIngredients(RecipeModel recipe) {
    return recipe.ingredients;
  }
}
