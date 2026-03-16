// Typed exception hierarchy for the TempHist app.
// All app-specific exceptions extend [AppException] so callers can catch
// broad or narrow categories as needed.

/// Base class for all app-specific exceptions.
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => cause != null ? '$message (cause: $cause)' : message;
}

/// Thrown when an API request returns a non-success HTTP status code.
class ApiException extends AppException {
  final int statusCode;
  final String endpoint;

  const ApiException(this.statusCode, this.endpoint, [Object? cause])
      : super('API error $statusCode on $endpoint', cause);
}

/// Thrown when the API returns an empty or unparseable response body.
class ApiResponseException extends AppException {
  const ApiResponseException(String detail, [Object? cause])
      : super('Invalid API response: $detail', cause);
}

/// Thrown when an API request exceeds its timeout.
class ApiTimeoutException extends AppException {
  final String endpoint;

  const ApiTimeoutException(this.endpoint, [Object? cause])
      : super('Request timed out: $endpoint', cause);
}

/// Thrown when the API returns HTTP 429.
class RateLimitException extends AppException {
  const RateLimitException(String detail) : super('Rate limit exceeded: $detail');
}

/// Thrown when Firebase authentication fails.
class AuthException extends AppException {
  const AuthException(String detail, [Object? cause])
      : super('Authentication failed: $detail', cause);
}

/// Thrown when async job polling fails or times out.
class JobPollingException extends AppException {
  const JobPollingException(String detail, [Object? cause])
      : super('Job polling failed: $detail', cause);
}
