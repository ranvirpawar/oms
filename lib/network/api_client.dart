import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:lifenity_connect/network/session_coordinator.dart';

import '../services/auth_manager.dart';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_error.dart';
import 'retry_policy.dart';


/// Low-level, mostly-untyped response — kept as the transport primitive.
/// New code should prefer [APIClient.getTyped]/[postTyped]/etc.; this
/// stays available so every existing untyped call site keeps working
/// unmodified during migration.
class ApiResult {
  const ApiResult({required this.statusCode, required this.data});

  final int? statusCode;
  final dynamic data;

  Map<String, dynamic> get body =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{};

  List get list => data is List ? data as List : const [];
}

class TypedApiResult<T> {
  const TypedApiResult({required this.statusCode, required this.data});
  final int? statusCode;
  final T data;
}

enum BodyEncoding { json, formUrlEncoded, multipart }

/// Pure transport + error classification. Deliberately contains ZERO
/// references to GetX UI (no snackbar/dialog/navigation) — see the
/// architecture doc §5/§17 for why. All auth-state decisions are
/// delegated to [SessionManager]; all presentation decisions belong to
/// the caller (ViewModel/Controller layer), which maps [AppError] to a
/// ViewState however is appropriate for that screen.
class APIClient {
  APIClient({
    required Dio dio,
    required SessionCoordinator sessionManager,
    RetryPolicy retryPolicy = const RetryPolicy(),
    String? baseUrl,
  })  : _dio = dio,
        _sessionManager = sessionManager,
        _defaultRetryPolicy = retryPolicy {
    _dio.options = BaseOptions(
      baseUrl: baseUrl ?? _dio.options.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    );
  }

  final Dio _dio;
  final SessionCoordinator  _sessionManager;
  final RetryPolicy _defaultRetryPolicy;

  Dio get dio => _dio;

  // -----------------------------------------------------------------
  // Typed public API (preferred for new code)
  // -----------------------------------------------------------------

  Future<TypedApiResult<T>> getTyped<T>(
      String path, {
        required T Function(dynamic json) fromJson,
        Map<String, dynamic>? query,
        CancelToken? cancelToken,
        RetryPolicy? retryPolicy,
        bool requiresAuth = true,
      }) async {
    final raw = await get(
      path,
      queryParameters: query,
      cancelToken: cancelToken,
      retryPolicy: retryPolicy,
      requiresAuth: requiresAuth,
    );
    return _decode(raw, fromJson, path);
  }

  TypedApiResult<T> _decode<T>(ApiResult raw, T Function(dynamic) fromJson, String path) {
    try {
      return TypedApiResult(statusCode: raw.statusCode, data: fromJson(raw.data));
    } catch (e, st) {
      throw ResponseParsingError('Failed to parse response from $path', cause: e);
    }
  }

  // -----------------------------------------------------------------
  // Untyped verb methods (unchanged surface — existing call sites keep
  // compiling and working exactly as before)
  // -----------------------------------------------------------------

  Future<ApiResult> get(
      String url, {
        Map<String, dynamic>? queryParameters,
        bool isFormData = false,
        CancelToken? cancelToken,
        RetryPolicy? retryPolicy,
        bool requiresAuth = true,
      }) {
    return _request(
      'GET',
      url,
      queryParameters: queryParameters,
      isFormData: isFormData,
      cancelToken: cancelToken,
      retryPolicy: retryPolicy,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResult> post(
      String url, {
        dynamic data,
        bool isJson = true,
        bool isFormData = false,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        RetryPolicy? retryPolicy,
        bool requiresAuth = true,
      }) {
    return _request(
      'POST',
      url,
      data: data,
      isJson: isJson,
      isFormData: isFormData,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      // POST defaults to no-retry unless caller explicitly opts in via
      // retryPolicy — see RetryPolicy.isMethodRetryable.
      retryPolicy: retryPolicy ?? RetryPolicy.none,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResult> put(
      String url, {
        dynamic data,
        bool isJson = true,
        bool isFormData = false,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        RetryPolicy? retryPolicy,
        bool requiresAuth = true,
      }) {
    return _request(
      'PUT',
      url,
      data: data,
      isJson: isJson,
      isFormData: isFormData,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      retryPolicy: retryPolicy,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResult> delete(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        bool isFormData = false,
        CancelToken? cancelToken,
        RetryPolicy? retryPolicy,
        bool requiresAuth = true,
      }) {
    return _request(
      'DELETE',
      url,
      data: data,
      isFormData: isFormData,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      retryPolicy: retryPolicy,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResult> patch(
      String url, {
        dynamic data,
        bool isJson = true,
        bool isFormData = false,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        RetryPolicy? retryPolicy,
        bool requiresAuth = true,
      }) {
    return _request(
      'PATCH',
      url,
      data: data,
      isJson: isJson,
      isFormData: isFormData,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      retryPolicy: retryPolicy,
      requiresAuth: requiresAuth,
    );
  }

  // -----------------------------------------------------------------
  // Core request + retry loop
  // -----------------------------------------------------------------

  Future<ApiResult> _request(
      String method,
      String url, {
        dynamic data,
        bool isJson = true,
        bool isFormData = false,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        RetryPolicy? retryPolicy,
        bool requiresAuth = true,
      }) async {
    final policy = retryPolicy ?? _defaultRetryPolicy;
    final requestId = _newRequestId();
    // Stamp the session generation at request start (architecture doc
    // §10, cases 5/10) — callers further up the stack (repositories)
    // can compare this against SessionManager.currentGeneration when
    // the response arrives to discard zombie responses.
    final startGeneration = _sessionManager.currentGeneration;

    int attempt = 0;
    var hasRetriedAfterRefresh = false;

    while (true) {
      attempt++;
      final stopwatch = Stopwatch()..start();
      Map<String, dynamic> headers = {};

      try {
        headers = await _buildHeaders(isJson: isFormData ? false : isJson, requiresAuth: requiresAuth);
        final body = isFormData ? (data is FormData ? data : FormData.fromMap(data ?? <String, dynamic>{})) : data;

        final response = await _dio.request(
          url,
          data: body,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          options: Options(headers: headers, method: method),
        );
        stopwatch.stop();

        _logCall(
          method: method,
          url: url,
          requestId: requestId,
          body: body,
          headers: headers,
          durationMs: stopwatch.elapsedMilliseconds,
          attempt: attempt,
          response: response,
        );

        return ApiResult(statusCode: response.statusCode, data: _processResponseData(response.data));
      } on DioException catch (e) {
        stopwatch.stop();
        _logCall(
          method: method,
          url: url,
          requestId: requestId,
          body: data,
          headers: headers,
          durationMs: stopwatch.elapsedMilliseconds,
          attempt: attempt,
          error: e,
        );

        if (e.type == DioExceptionType.cancel) {
          throw RequestCancelledError(requestId: requestId);
        }

        // --- 401 handling: delegated entirely to SessionManager. This
        // is deliberately OUTSIDE the generic retry policy and capped
        // at exactly one retry-after-refresh, per request. ---
        if (e.response?.statusCode == 401 && requiresAuth && !hasRetriedAfterRefresh) {
          hasRetriedAfterRefresh = true;
          final shouldRetry = await _sessionManager.handleUnauthorized(requestId: requestId);
          if (shouldRetry) {
            continue; // retry the request once with the refreshed token
          }
          throw const SessionExpiredError();
        }
        if (e.response?.statusCode == 401) {
          throw UnauthorizedError('Unauthorized', requestId: requestId);
        }

        final appError = _classify(e, requestId: requestId);

        final canRetry = attempt < policy.maxAttempts &&
            policy.isMethodRetryable(method) &&
            policy.isRetryableFailure(e);

        if (canRetry) {
          final delay = policy.delayForAttempt(attempt, error: e);
          await Future.delayed(delay);
          continue;
        }

        throw appError;
      } catch (e, stackTrace) {
        stopwatch.stop();
        if (kDebugMode) {
          log('💥 UNEXPECTED API ERROR: $method $url -> $e\n$stackTrace');
        }
        throw UnknownError(e.toString(), requestId: requestId, cause: e);
      }
    }
  }

  Future<Map<String, dynamic>> _buildHeaders({required bool isJson, required bool requiresAuth}) async {
    final headers = <String, dynamic>{
      'Content-Type': isJson ? 'application/json' : 'application/x-www-form-urlencoded',
    };
    if (requiresAuth) {
      final token = await _sessionManager.currentAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // -----------------------------------------------------------------
  // Error classification: DioException -> AppError (see architecture
  // doc §7 for the full table this implements)
  // -----------------------------------------------------------------

  AppError _classify(DioException e, {required String requestId}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError('Request timed out', requestId: requestId, cause: e);
      case DioExceptionType.connectionError:
        return NoInternetError(requestId: requestId);
      case DioExceptionType.badCertificate:
        return TlsError('Secure connection failed', requestId: requestId, cause: e);
      case DioExceptionType.cancel:
        return RequestCancelledError(requestId: requestId);
      case DioExceptionType.badResponse:
        return _classifyStatus(e, requestId: requestId);
      case DioExceptionType.unknown:
        return UnknownError(e.message ?? 'Unknown network error', requestId: requestId, cause: e);
    }
  }

  AppError _classifyStatus(DioException e, {required String requestId}) {
    final status = e.response?.statusCode;
    final responseData = e.response?.data;
    final message = _extractMessage(responseData) ?? e.message ?? 'An unexpected error occurred';

    switch (status) {
      case 403:
        return ForbiddenError(message, requestId: requestId);
      case 404:
        return NotFoundError(message, requestId: requestId);
      case 409:
        return ConflictError(message, requestId: requestId);
      case 422:
        return ValidationError(message, _extractFieldErrors(responseData), requestId: requestId);
      case 429:
        return RateLimitedError(
          message,
          retryAfter: _retryAfter(e),
          requestId: requestId,
        );
      default:
        if (status != null && status >= 500) {
          return ServerError(message, statusCode: status, requestId: requestId, cause: e);
        }
        return UnknownError(message, statusCode: status, requestId: requestId, cause: e);
    }
  }

  Duration? _retryAfter(DioException e) {
    final value = e.response?.headers.value('retry-after');
    final seconds = value != null ? int.tryParse(value) : null;
    return seconds != null ? Duration(seconds: seconds) : null;
  }

  String? _extractMessage(dynamic responseData) {
    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }
    return null;
  }

  Map<String, List<String>> _extractFieldErrors(dynamic responseData) {
    if (responseData is Map && responseData['errors'] is Map) {
      final errors = responseData['errors'] as Map;
      return errors.map((k, v) => MapEntry(
        k.toString(),
        v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
      ));
    }
    return const {};
  }

  // -----------------------------------------------------------------
  // Response decoding
  // -----------------------------------------------------------------

  dynamic _processResponseData(dynamic data) {
    if (data == null) return <String, dynamic>{}; // e.g. 204 No Content
    if (data is String) {
      if (data.isEmpty) return <String, dynamic>{};
      try {
        return json.decode(data);
      } on FormatException {
        return {'data': data};
      }
    }
    return data;
  }

  // -----------------------------------------------------------------
  // Logging (debug-verbose; production-structured — see architecture
  // doc §13 for the full logging policy this implements)
  // -----------------------------------------------------------------

  String _newRequestId() => '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';

  Map<String, dynamic> _redactedHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) copy['Authorization'] = 'Bearer ***';
    return copy;
  }

  dynamic _redactedBody(dynamic body) {
    const sensitiveKeys = ['password', 'token', 'secret', 'ssn', 'cardnumber', 'cvv'];
    if (body is Map) {
      final copy = Map<String, dynamic>.from(body);
      for (final key in copy.keys.toList()) {
        if (sensitiveKeys.any((s) => key.toString().toLowerCase().contains(s))) {
          copy[key] = '***';
        }
      }
      return copy;
    }
    return body;
  }

  void _logCall({
    required String method,
    required String url,
    required String requestId,
    required dynamic body,
    required Map<String, dynamic> headers,
    required int durationMs,
    required int attempt,
    Response? response,
    DioException? error,
  }) {
    if (!kDebugMode) {
      // Production: emit a structured, low-cardinality event to your
      // APM/log pipeline instead of a pretty-printed block. Left as a
      // hook — wire to Sentry/Crashlytics/Datadog breadcrumbs here.
      return;
    }

    final ok = error == null;
    final statusCode = response?.statusCode ?? error?.response?.statusCode;
    final buffer = StringBuffer()
      ..writeln('${ok ? '✅' : '❌'} $method $url  [reqId=$requestId attempt=$attempt]');

    if (body != null) {
      buffer.writeln('   body    : ${_redactedBody(body is FormData ? body.fields : body)}');
    }
    buffer.writeln('   headers : ${_redactedHeaders(headers)}');
    buffer.writeln('   status  : ${statusCode ?? '—'} (${durationMs}ms)');
    buffer.write('   response: ${ok ? response?.data : (error!.response?.data ?? error.message)}');

    log(buffer.toString());
  }
}

/*class ApiResult {
  const ApiResult({required this.statusCode, required this.data});

  final int? statusCode;

  /// The decoded response payload — a Map, a List, or a primitive,
  /// whatever the server actually sent. Never re-wrapped.
  final dynamic data;

  /// Convenience getter for endpoints that return a JSON object
  /// (e.g. `{ "status": "Success", "output": [...] }`).
  Map<String, dynamic> get body =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{};

  /// Convenience getter for endpoints that return a bare JSON array.
  List get list => data is List ? data as List : const [];
}


typedef UnauthorizedCallback = void Function();

class APIClient {
  APIClient({bool isTestMode = false}) : _isTestMode = isTestMode {
    _initDio();
  }

  final Dio _dio = Dio();
  final bool _isTestMode;
  final AuthManager _authManager = getx.Get.find<AuthManager>();
  final Connectivity _connectivity = Connectivity();

  UnauthorizedCallback? onUnauthorized;

  void _initDio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      // Only 2xx counts as success. Everything else throws a DioException
      // and is handled centrally in `_handleDioError`.
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    );
  }

  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _showNoInternetDialog() {
    if (getx.Get.isDialogOpen ?? false) return;
    getx.Get.dialog(
      AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text('Please check your internet connection and try again.'),
        actions: [
          TextButton(onPressed: () => getx.Get.back(), child: const Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _redirectToMaintenanceMode(String message) async {
    await _authManager.logoutUser();
    // getx.Get.offAll(() => const MaintenanceScreen(), arguments: {'message': message});
  }

  /// Header injection. Token comes solely from [AuthManager]'s in-memory
  /// cache (backed by secure storage) — never from the user-data blob.
  Future<Map<String, dynamic>> _getHeaders({required bool isJson}) async {
    final headers = <String, dynamic>{
      'Content-Type': isJson ? 'application/json' : 'application/x-www-form-urlencoded',
    };

    final token = _authManager.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ---------------------------------------------------------------------
  // LOGGING (redacts secrets; only runs in debug builds)
  // ---------------------------------------------------------------------

  Map<String, dynamic> _redactedHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) copy['Authorization'] = 'Token ***';
    return copy;
  }

  dynamic _redactedBody(dynamic body) {
    if (body is Map) {
      final copy = Map<String, dynamic>.from(body);
      for (final key in copy.keys.toList()) {
        if (key.toString().toLowerCase().contains('password')) copy[key] = '***';
      }
      return copy;
    }
    return body;
  }

  /// Shows enough of the token to confirm it's the *right* one across
  /// requests without printing the whole thing: `(none)` if missing,
  /// otherwise `eyJhbGciO...9TSM4RZ (87 chars)`.
  String _describeToken(Map<String, dynamic> headers) {
    final auth = headers['Authorization'] as String?;
    if (auth == null || !auth.startsWith('Bearer ') || auth.length <= 6) {
      return '(none — request is unauthenticated)';
    }
    final token = auth.substring(6);
    if (token.length <= 16) return '$token (${token.length} chars)';
    return '${token.substring(0, 8)}...${token.substring(token.length - 8)} (${token.length} chars)';
  }

  /// Single log block per request, emitted once the outcome (success or
  /// error) is known — never split across two log calls — so concurrent
  /// requests can't interleave into a misleading order. Order is always:
  /// body -> url -> token -> response.
  void _logCall({
    required String method,
    required String url,
    required dynamic body,
    required Map<String, dynamic>? queryParameters,
    required Map<String, dynamic> headers,
    required int durationMs,
    Response? response,
    DioException? error,
  }) {
    if (!kDebugMode) return;

    final ok = error == null;
    final statusCode = response?.statusCode ?? error?.response?.statusCode;
    final buffer = StringBuffer()
      ..writeln('${ok ? '✅' : '❌'} $method $url');

    if (body != null) {
      buffer.writeln('   body    : ${_redactedBody(body is FormData ? body.fields : body)}');
    }
    if (queryParameters != null && queryParameters.isNotEmpty) {
      buffer.writeln('   params  : $queryParameters');
    }
    buffer.writeln('   url     : $url');
    buffer.writeln('   token   : ${_describeToken(headers)}');
    buffer.writeln('   status  : ${statusCode ?? '—'} (${durationMs}ms)');
    buffer.write('   response: ${ok ? response?.data : (error!.response?.data ?? error.message)}');

    log(buffer.toString());
  }

  // ---------------------------------------------------------------------
  // GENERIC REQUEST
  // ---------------------------------------------------------------------

  Future<ApiResult> _request(
      String method,
      String url, {
        dynamic data,
        bool isJson = true,
        bool isFormData = false,
        Map<String, dynamic>? queryParameters,
        bool logoutOnUnauthorized = true,
      }) async {
    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetDialog();
      throw DioException(
        requestOptions: RequestOptions(path: url, method: method),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final useJson = isFormData ? false : isJson;
      final body = isFormData ? (data is FormData ? data : FormData.fromMap(data ?? <String, dynamic>{})) : data;
      final headers = await _getHeaders(isJson: useJson);
      final options = Options(headers: headers, method: method);

      final response = await _dio.request(url, data: body, queryParameters: queryParameters, options: options);
      stopwatch.stop();

      _logCall(
        method: method,
        url: url,
        body: body,
        queryParameters: queryParameters,
        headers: headers,
        durationMs: stopwatch.elapsedMilliseconds,
        response: response,
      );

      return ApiResult(statusCode: response.statusCode, data: _processResponseData(response.data));
    } on DioException catch (e) {
      stopwatch.stop();
      _logCall(
        method: method,
        url: url,
        body: data,
        queryParameters: queryParameters,
        headers: e.requestOptions.headers.map((k, v) => MapEntry(k, v)),
        durationMs: stopwatch.elapsedMilliseconds,
        error: e,
      );

      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        if (!hasInternet) {
          _showNoInternetDialog();
        } else {
          _showToast('Unable to connect to server. Please try again later.');
        }
      } else {
        _handleDioError(e, logoutOnUnauthorized: logoutOnUnauthorized);
      }

      rethrow;
    } catch (e, stackTrace) {
      stopwatch.stop();
      if (kDebugMode) {
        log('💥 UNEXPECTED API ERROR: $method $url -> $e\n$stackTrace');
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // HTTP METHODS
  // ---------------------------------------------------------------------

  Future<ApiResult> get(String url, {Map<String, dynamic>? queryParameters, bool isFormData = false}) {
    return _request('GET', url, queryParameters: queryParameters, isJson: true, isFormData: isFormData);
  }

  Future<ApiResult> post(String url,
      {dynamic data, bool isJson = true, bool isFormData = false, Map<String, dynamic>? queryParameters}) {
    return _request('POST', url, data: data, isJson: isJson, isFormData: isFormData, queryParameters: queryParameters);
  }

  Future<ApiResult> put(String url,
      {dynamic data, bool isJson = true, bool isFormData = false, Map<String, dynamic>? queryParameters}) {
    return _request('PUT', url, data: data, isJson: isJson, isFormData: isFormData, queryParameters: queryParameters);
  }

  Future<ApiResult> delete(String url, {dynamic data, Map<String, dynamic>? queryParameters, bool isFormData = false}) {
    return _request('DELETE', url, data: data, isJson: true, isFormData: isFormData, queryParameters: queryParameters);
  }

  Future<ApiResult> patch(String url,
      {dynamic data, bool isJson = true, bool isFormData = false, Map<String, dynamic>? queryParameters}) {
    return _request('PATCH', url, data: data, isJson: isJson, isFormData: isFormData, queryParameters: queryParameters);
  }

  // ---------------------------------------------------------------------
  // RESPONSE PROCESSING
  // ---------------------------------------------------------------------

  /// Decodes string bodies; Map/List bodies (already decoded by Dio) are
  /// returned as-is — no extra wrapping, so `result.data` is always the
  /// real payload shape the server sent.
  dynamic _processResponseData(dynamic data) {
    if (data is String) {
      if (data.isEmpty) return <String, dynamic>{};
      try {
        return json.decode(data);
      } on FormatException {
        return {'data': data};
      }
    }
    return data;
  }

  // ---------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------

  String? _extractMessage(dynamic responseData) {
    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }
    return null;
  }

  Future<void> _handleDioError(DioException e, {bool logoutOnUnauthorized = true}) async {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    final errorMessage = _extractMessage(responseData) ?? e.message ?? 'An unexpected error occurred';

    // Maintenance mode — a custom app-level code, not a real HTTP status.
    if (statusCode == 1999 || (responseData is Map && responseData['statusCode'] == 1999)) {
      _redirectToMaintenanceMode(errorMessage);
      return;
    }

    switch (statusCode) {
      case 401:
        if (kDebugMode) {
          log('🔐 401 Unauthorized - Logging out user');
        }
        _showToast('Session Expired Please log in again');
        if (logoutOnUnauthorized) {
          await _authManager.logoutUser();

          if (kDebugMode) {
            log('🔐 User logged out successfully after 401');
          }

          // Optional navigation
          onUnauthorized?.call();
          // getx.Get.offAllNamed(Routes.login);
        } else {
          _showToast(errorMessage);
        }
        break;
      case 400:
        _showToast(errorMessage);
        break;
      case 403:
        _showToast("You don't have permission to do that.");
        break;
      case 404:
        _showToast('The requested resource was not found.');
        break;
      case 405:
      // This is almost always a wrong HTTP verb against the endpoint
      // (e.g. calling GET on something that only accepts POST) —
      // a dev/config bug, not something the user caused.
        if (kDebugMode) {
          log('⚠️ 405 Method Not Allowed for ${e.requestOptions.method} '
              '${e.requestOptions.uri} — check the endpoint expects this verb.');
        }
        _showToast('Something went wrong. Please try again later.');
        break;
      case 422:
        _showToast(errorMessage);
        break;
      case 429:
        _showToast('Too many requests. Please wait a moment and try again.');
        break;
      default:
        if (statusCode != null && statusCode >= 500) {
          _showToast('Server error. Please try again later.');
        } else {
          _showToast(errorMessage);
        }
    }

    if (kDebugMode) {
      log('API Error $statusCode: $errorMessage');
    }
  }

  void _showToast(String message) {
    getx.Get.snackbar(
      'Server Error',
      message,
      snackPosition: getx.SnackPosition.BOTTOM,
      // backgroundColor: AppColors.primary,
      colorText: Colors.white,
      borderRadius: 8.0,
      duration: const Duration(seconds: 1),
      isDismissible: true,
    );
  }

  Dio get dio => _dio;
}*/
