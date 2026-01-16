import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantry_app/data/datasources/supabase_auth_service.dart';
import 'package:pantry_app/data/datasources/supabase_database_service.dart';
import 'package:pantry_app/data/datasources/supabase_storage_service.dart';
import 'package:pantry_app/data/datasources/themealdb_api_service.dart';
import 'package:pantry_app/data/models/user_model.dart';

// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Services providers
final authServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService(ref.watch(supabaseProvider));
});

final databaseServiceProvider = Provider<SupabaseDatabaseService>((ref) {
  return SupabaseDatabaseService(ref.watch(supabaseProvider));
});

final storageServiceProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService(ref.watch(supabaseProvider));
});

final mealDbServiceProvider = Provider<TheMealDbService>((ref) {
  return TheMealDbService();
});

// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

// Current user provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  return ref.watch(authServiceProvider).getCurrentUser();
});

// Auth notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final SupabaseAuthService authService;
  final Ref ref;

  AuthNotifier(this.authService, this.ref) : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  void _initializeAuth() {
    final user = authService.getCurrentUser();
    if (user != null) {
      state = AsyncValue.data(user);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('AuthNotifier: Starting signup for $email');
      final response = await authService.signUp(
        email: email,
        password: password,
      );
      print('AuthNotifier: Signup successful for user ${response.user?.id}');

      // Create user record in database
      if (response.user != null) {
        try {
          print('AuthNotifier: Creating user record in database');
          final dbService = ref.read(databaseServiceProvider);
          await dbService.createUser(
            UserModel(
              id: response.user!.id,
              email: email,
              createdAt: DateTime.now(),
            ),
          );
          print('AuthNotifier: User record created successfully');
        } catch (dbError) {
          print(
              'AuthNotifier: Warning - Failed to create user record: $dbError');
          // Don't fail the signup if database record creation fails
        }
      }

      state = AsyncValue.data(response.user);
    } catch (e, stack) {
      print('AuthNotifier: Signup error: $e');
      state = AsyncValue.error(e, stack);
      rethrow; // Re-throw so calling code can catch and handle
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('AuthNotifier: Starting signin for $email');
      final response = await authService.signIn(
        email: email,
        password: password,
      );
      print(
          'AuthNotifier: Signin successful for user ${response.user?.id}, session: ${response.session != null}');
      state = AsyncValue.data(response.user);
      print('AuthNotifier: State updated with user');
    } catch (e, stack) {
      print('AuthNotifier: Signin error: $e');
      print('Stack: $stack');
      state = AsyncValue.error(e, stack);
      rethrow; // Re-throw so calling code can catch and handle
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider), ref);
});

// User profile provider
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  final user = authState?.session?.user;
  if (user == null) return null;

  try {
    final dbService = ref.watch(databaseServiceProvider);
    final userData = await dbService.getUserById(user.id);
    return userData;
  } catch (e) {
    print('Error loading user profile: $e');
    // Return basic user info from auth if database fetch fails
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );
  }
});

// User profile notifier for updates
class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseDatabaseService dbService;
  final Ref ref;

  UserProfileNotifier({
    required this.dbService,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<void> updateUserName(String userId, String name) async {
    state = const AsyncValue.loading();
    try {
      print('Updating user name to: $name');
      final currentProfile = await ref.read(userProfileProvider.future);
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedUser = currentProfile.copyWith(name: name);
      await dbService.updateUser(updatedUser);

      // Invalidate to refresh
      ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
      print('User name updated successfully');
    } catch (e, stack) {
      print('Error updating user name: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  return UserProfileNotifier(
    dbService: ref.watch(databaseServiceProvider),
    ref: ref,
  );
});
