import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:pantry_app/core/utils/exceptions.dart' as app_exceptions;
import 'package:gotrue/gotrue.dart' as gotrue;

class SupabaseAuthService {
  final SupabaseClient _supabaseClient;

  SupabaseAuthService(this._supabaseClient);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      print('SupabaseAuthService: Attempting signup with email: $email');
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      print(
          'SupabaseAuthService: Signup response - User ID: ${response.user?.id}, Session: ${response.session != null}');
      return response;
    } on gotrue.AuthException catch (e) {
      print('SupabaseAuthService: AuthException during signup: ${e.message}');
      throw app_exceptions.AppExceptions.auth(
        message: e.message,
      );
    } catch (e) {
      print('SupabaseAuthService: Exception during signup: $e');
      throw app_exceptions.AppExceptions.auth(
        message: 'Sign up failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('SupabaseAuthService: Attempting signin with email: $email');
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print(
          'SupabaseAuthService: Signin response - User ID: ${response.user?.id}, Session: ${response.session != null}');
      return response;
    } on gotrue.AuthException catch (e) {
      print('SupabaseAuthService: AuthException during signin: ${e.message}');
      throw app_exceptions.AppExceptions.auth(
        message: e.message,
      );
    } catch (e) {
      print('SupabaseAuthService: Exception during signin: $e');
      throw app_exceptions.AppExceptions.auth(
        message: 'Sign in failed: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on gotrue.AuthException catch (e) {
      throw app_exceptions.AppExceptions.auth(
        message: e.message,
      );
    } catch (e) {
      throw app_exceptions.AppExceptions.auth(
        message: 'Sign out failed: ${e.toString()}',
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } on gotrue.AuthException catch (e) {
      throw app_exceptions.AppExceptions.auth(
        message: e.message,
      );
    } catch (e) {
      throw app_exceptions.AppExceptions.auth(
        message: 'Password reset failed: ${e.toString()}',
      );
    }
  }

  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return _supabaseClient.auth.onAuthStateChange;
  }

  bool isUserLoggedIn() {
    return _supabaseClient.auth.currentUser != null;
  }
}
