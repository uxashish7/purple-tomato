class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) {
      return '[$code] $message';
    }
    return message;
  }
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});
}

class ApiException extends AppException {
  final int? statusCode;

  ApiException(super.message, {this.statusCode, super.code, super.originalError});
}

class CacheException extends AppException {
  CacheException(super.message, {super.code, super.originalError});
}
