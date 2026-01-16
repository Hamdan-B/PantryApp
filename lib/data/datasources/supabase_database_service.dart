import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantry_app/core/constants/app_constants.dart';
import 'package:pantry_app/core/utils/exceptions.dart';
import 'package:pantry_app/data/models/user_model.dart';

class SupabaseDatabaseService {
  final SupabaseClient _supabaseClient;

  SupabaseDatabaseService(this._supabaseClient);

  // User operations
  Future<void> createUser(UserModel user) async {
    try {
      await _supabaseClient.from(AppConstants.usersTable).insert(
            user.toJson(),
          );
    } on PostgrestException catch (e) {
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to create user: ${e.toString()}',
      );
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.usersTable)
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null; // User not found
      }
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get user: ${e.toString()}',
      );
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _supabaseClient
          .from(AppConstants.usersTable)
          .update(user.toJson())
          .eq('id', user.id);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to update user: ${e.toString()}',
      );
    }
  }

  // Pantry items operations
  Future<Map<String, dynamic>> addPantryItem(Map<String, dynamic> item) async {
    try {
      print('[DB] Adding pantry item: $item');
      final response = await _supabaseClient
          .from(AppConstants.pantryItemsTable)
          .insert(item)
          .select()
          .single();
      print('[DB] Item inserted successfully: $response');
      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      print('[DB] PostgrestException: ${e.message} (code: ${e.code})');
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      print('[DB] Error adding pantry item: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPantryItems(String userId) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.pantryItemsTable)
          .select()
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get pantry items: ${e.toString()}',
      );
    }
  }

  Future<void> updatePantryItem(
      String itemId, Map<String, dynamic> data) async {
    try {
      await _supabaseClient
          .from(AppConstants.pantryItemsTable)
          .update(data)
          .eq('id', itemId);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to update pantry item: ${e.toString()}',
      );
    }
  }

  Future<void> deletePantryItem(String itemId) async {
    try {
      await _supabaseClient
          .from(AppConstants.pantryItemsTable)
          .delete()
          .eq('id', itemId);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to delete pantry item: ${e.toString()}',
      );
    }
  }

  // Planner operations
  Future<void> addPlannedMeal(Map<String, dynamic> meal) async {
    try {
      print('Adding planned meal: $meal');
      final result = await _supabaseClient
          .from(AppConstants.plannerTable)
          .insert(meal)
          .select();
      print('Planned meal added successfully: $result');
    } on PostgrestException catch (e) {
      print(
          'PostgrestException adding planned meal: ${e.message} (code: ${e.code})');
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      print('Error adding planned meal: $e');
      throw DatabaseException(
        message: 'Failed to add planned meal: ${e.toString()}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPlannedMealsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      // Create start and end of day for the date range
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _supabaseClient
          .from(AppConstants.plannerTable)
          .select()
          .eq('user_id', userId)
          .gte('date', startOfDay.toIso8601String())
          .lte('date', endOfDay.toIso8601String());
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      print(
          '[DB] PostgrestException in getPlannedMealsForDate: ${e.message} (code: ${e.code})');
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      print('[DB] Error getting planned meals: ${e.toString()}');
      throw DatabaseException(
        message: 'Failed to get planned meals: ${e.toString()}',
      );
    }
  }

  Future<void> deletePlannedMeal(String mealId) async {
    try {
      await _supabaseClient
          .from(AppConstants.plannerTable)
          .delete()
          .eq('id', mealId);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to delete planned meal: ${e.toString()}',
      );
    }
  }

  // Usage logs operations
  Future<void> addUsageLog(Map<String, dynamic> log) async {
    try {
      await _supabaseClient.from(AppConstants.usageLogsTable).insert(log);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to add usage log: ${e.toString()}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getUserUsageLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabaseClient
          .from(AppConstants.usageLogsTable)
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('used_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('used_at', endDate.toIso8601String());
      }

      final response = await query.order('used_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get usage logs: ${e.toString()}',
      );
    }
  }
}
