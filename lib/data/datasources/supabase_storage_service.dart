import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:pantry_app/core/constants/app_constants.dart';
import 'package:pantry_app/core/utils/exceptions.dart' as app_exceptions;
import 'package:storage_client/storage_client.dart' as storage_client;

class SupabaseStorageService {
  final SupabaseClient _supabaseClient;

  SupabaseStorageService(this._supabaseClient);

  Future<String> uploadUserAvatar(String userId, File imageFile) async {
    try {
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}';

      await _supabaseClient.storage
          .from(AppConstants.userAvatarsBucket)
          .upload(fileName, imageFile);

      final url = _supabaseClient.storage
          .from(AppConstants.userAvatarsBucket)
          .getPublicUrl(fileName);

      return url;
    } on storage_client.StorageException catch (e) {
      throw app_exceptions.AppExceptions.storage(
        message: 'Failed to upload avatar: ${e.message}',
      );
    } catch (e) {
      throw app_exceptions.AppExceptions.storage(
        message: 'Failed to upload avatar: ${e.toString()}',
      );
    }
  }

  Future<void> deleteUserAvatar(String avatarUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      // Find index of bucket name and extract path after it
      final bucketIndex = pathSegments.indexOf(AppConstants.userAvatarsBucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        await _supabaseClient.storage
            .from(AppConstants.userAvatarsBucket)
            .remove([filePath]);
      }
    } on storage_client.StorageException catch (e) {
      throw app_exceptions.AppExceptions.storage(
        message: 'Failed to delete avatar: ${e.message}',
      );
    } catch (e) {
      throw app_exceptions.AppExceptions.storage(
        message: 'Failed to delete avatar: ${e.toString()}',
      );
    }
  }

  Future<String> updateUserAvatar(
      String userId, String? oldAvatarUrl, File imageFile) async {
    if (oldAvatarUrl != null) {
      try {
        await deleteUserAvatar(oldAvatarUrl);
      } catch (e) {
        // Log but don't fail if old avatar deletion fails
        print('Failed to delete old avatar: $e');
      }
    }
    return uploadUserAvatar(userId, imageFile);
  }
}
