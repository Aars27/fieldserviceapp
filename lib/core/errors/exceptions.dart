class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, {this.statusCode});
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);
}

/// Thrown when a request is cancelled deliberately, e.g. debounced search
/// firing a new request before the previous one resolves. Repositories
/// should swallow this rather than surfacing it as an error to the UI.
class RequestCancelledException implements Exception {}
