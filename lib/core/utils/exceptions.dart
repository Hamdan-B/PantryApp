class AppExceptions implements Exception {
  final String message;
  final String? code;

  AppExceptions({required this.message, this.code});

  @override
  String toString() => message;

  /// Factory constructors for creating specific exception types
  factory AppExceptions.auth({required String message, String? code}) =>
      AuthException(message: message, code: code);

  factory AppExceptions.database({required String message, String? code}) =>
      DatabaseException(message: message, code: code);

  factory AppExceptions.api({required String message, String? code}) =>
      ApiException(message: message, code: code);

  factory AppExceptions.storage({required String message, String? code}) =>
      StorageException(message: message, code: code);

  factory AppExceptions.validation({required String message, String? code}) =>
      ValidationException(message: message, code: code);
}

class AuthException extends AppExceptions {
  AuthException({required String message, String? code})
      : super(message: message, code: code);
}

class DatabaseException extends AppExceptions {
  DatabaseException({required String message, String? code})
      : super(message: message, code: code);
}

class ApiException extends AppExceptions {
  ApiException({required String message, String? code})
      : super(message: message, code: code);
}

class StorageException extends AppExceptions {
  StorageException({required String message, String? code})
      : super(message: message, code: code);
}

class ValidationException extends AppExceptions {
  ValidationException({required String message, String? code})
      : super(message: message, code: code);
}
