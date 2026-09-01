/// Structured, UI-agnostic error taxonomy for the networking layer.
///
/// The transport layer (`APIClient`) only ever throws these — never touches
/// `BuildContext`, GetX, snackbars, or dialogs. Presentation decisions live
/// entirely at the call site (ViewModel/Controller), which is what makes
/// this layer unit-testable and lets different screens react differently
/// to the same error type.
library app_error;

sealed class AppError implements Exception {
  const AppError(this.message, {this.statusCode, this.requestId, this.cause});

  /// Human-readable, non-sensitive summary. Safe to log; NOT guaranteed to
  /// be a good end-user string for every locale/context — UI layers should
  /// generally map the *type* of this error to their own copy rather than
  /// displaying [message] verbatim in production UI.
  final String message;

  final int? statusCode;

  /// Correlates this error back to a single logged request across retries.
  final String? requestId;

  /// The underlying exception (DioException, FormatException, etc.), kept
  /// for logging/telemetry — never surfaced to the user.
  final Object? cause;

  @override
  String toString() => '$runtimeType(status: $statusCode, message: $message)';
}

class NoInternetError extends AppError {
  const NoInternetError({super.requestId})
      : super('No internet connection');
}

class TimeoutError extends AppError {
  const TimeoutError(super.message, {super.requestId, super.cause});
}

class TlsError extends AppError {
  const TlsError(super.message, {super.requestId, super.cause})
      : super();
}

/// Only reaches call sites *after* the SessionManager has already tried
/// (and either isn't allowed, or failed) to refresh — see SessionManager.
/// Raw 401s never leak past the session layer as this type mid-refresh.
class UnauthorizedError extends AppError {
  const UnauthorizedError(super.message, {super.requestId})
      : super(statusCode: 401);
}

/// Terminal: refresh was attempted and failed, or there is no refresh
/// path. The app-shell listener (single subscriber) reacts to this via
/// SessionEventBus, not via this exception directly reaching a screen.
class SessionExpiredError extends AppError {
  const SessionExpiredError({super.requestId})
      : super('Your session has expired. Please sign in again.');
}

class ForbiddenError extends AppError {
  const ForbiddenError(super.message, {super.requestId})
      : super(statusCode: 403);
}

class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.requestId})
      : super(statusCode: 404);
}

class ConflictError extends AppError {
  const ConflictError(super.message, {super.requestId})
      : super(statusCode: 409);
}

class ValidationError extends AppError {
  const ValidationError(
    super.message,
    this.fieldErrors, {
    super.requestId,
  }) : super(statusCode: 422);

  final Map<String, List<String>> fieldErrors;
}

class RateLimitedError extends AppError {
  const RateLimitedError(super.message, {this.retryAfter, super.requestId})
      : super(statusCode: 429);

  final Duration? retryAfter;
}

class ServerError extends AppError {
  const ServerError(super.message, {super.statusCode, super.requestId, super.cause});
}

class ResponseParsingError extends AppError {
  const ResponseParsingError(super.message, {super.requestId, super.cause})
      : super();
}

class RequestCancelledError extends AppError {
  const RequestCancelledError({super.requestId}) : super('Request cancelled');
}

class UnknownError extends AppError {
  const UnknownError(super.message, {super.statusCode, super.requestId, super.cause});
}
