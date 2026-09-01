import 'dart:math';

import 'package:dio/dio.dart';

/// Decides, given an error and how many attempts have already happened,
/// whether to retry and how long to wait first.
///
/// Kept as a standalone class (not inlined in APIClient) specifically so
/// it can be unit-tested by feeding it a sequence of exceptions and
/// asserting the resulting delay/attempt sequence — no Dio, no network,
/// no async timers required beyond fake_async in tests.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 5),
    this.backoffFactor = 2.0,
    this.jitterRatio = 0.2,
  });

  /// A policy that never retries — useful for non-idempotent POSTs or
  /// endpoints explicitly marked "don't retry me" (e.g. payment calls
  /// without a server-side idempotency key).
  static const RetryPolicy none = RetryPolicy(maxAttempts: 1);

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffFactor;
  final double jitterRatio;

  /// Returns true if [method] is safe to retry automatically by default.
  /// POST is excluded unless the caller opts in explicitly (idempotency
  /// key semantics are the caller's responsibility, not this policy's).
  bool isMethodRetryable(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
      case 'HEAD':
      case 'PUT':
      case 'DELETE':
      case 'PATCH':
        return true;
      case 'POST':
        return false;
      default:
        return false;
    }
  }

  /// Whether this specific failure category is worth retrying at all.
  /// 401 is deliberately excluded — that's handled exclusively by
  /// SessionManager's refresh-and-retry-once flow, outside this policy.
  bool isRetryableFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badCertificate:
        return false; // never auto-retry TLS failures
      case DioExceptionType.cancel:
        return false; // cancellation always short-circuits
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == null) return false;
        return status == 429 || status == 502 || status == 503 || status == 504 || status >= 500;
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Computes the delay before the next attempt, honoring a server
  /// `Retry-After` header when present (429/503) in preference to the
  /// computed backoff — the server knows better than our guess.
  Duration delayForAttempt(int attemptNumber, {DioException? error}) {
    final retryAfter = _retryAfterHeader(error);
    if (retryAfter != null) return retryAfter;

    final exponential = baseDelay * pow(backoffFactor, attemptNumber - 1);
    final capped = exponential > maxDelay ? maxDelay : exponential;
    final jitterMs = capped.inMilliseconds * jitterRatio * (Random().nextDouble() * 2 - 1);
    final finalMs = (capped.inMilliseconds + jitterMs).clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: finalMs.round());
  }

  Duration? _retryAfterHeader(DioException? error) {
    final headerValue = error?.response?.headers.value('retry-after');
    if (headerValue == null) return null;
    final seconds = int.tryParse(headerValue);
    if (seconds != null) return Duration(seconds: seconds);
    return null; // (HTTP-date form intentionally not parsed here — extend if needed)
  }
}
