import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;

import '../services/auth_manager.dart';


class ApiResult {
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
}
/*
class APIClient {
  final Dio _dio = Dio();
  final bool _isTestMode;
  final AuthManager _authManager = getx.Get.put(AuthManager());
  final Connectivity _connectivity = Connectivity();

  /// Creates an instance of APIClient
  APIClient({bool isTestMode = false}) : _isTestMode = isTestMode {
    _initDio();
  }

  /// Initialize Dio with configurations and interceptors
  void _initDio() {
    // TODO: Remove SSL bypass logic if added for development/testing.
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 500),
      receiveTimeout: const Duration(seconds: 500),
      sendTimeout: const Duration(seconds: 500),
    );
  }

  /// Check if internet connection is available
  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();

    return connectivityResult != ConnectivityResult.none;
  }

  /// Show no internet connection dialog
  void _showNoInternetDialog() {
    getx.Get.dialog(
      AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text(
          'Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => getx.Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Redirect user to maintenance mode screen and logout
  Future<void> _redirectToMaintenanceMode(String message) async {
    // Logout the user
    await _authManager.logoutUser();

    // Navigate to maintenance screen
    getx.Get.offAll(
          () => const MaintenanceScreen(),
      arguments: {
        'message': message,
      },
    );
  }

  /// Gets the appropriate headers for the request
  Future<Map<String, dynamic>> _getHeaders({
    required bool isJson,
  }) async {
    final headers = <String, dynamic>{
      'Content-Type': isJson
          ? 'application/json'
          : 'application/x-www-form-urlencoded',
    };

    if (await _authManager.isUserLoggedIn()) {
      final token = await _authManager.getToken();

      if (kDebugMode) {
        log('Token: $token');
      }

      headers['Authorization'] = 'Token $token';
    }

    return headers;
  }

  // ---------------------------------------------------------------------------
  // REQUEST LOGGING
  // ---------------------------------------------------------------------------

  /// Log API request details
  void _logRequest({
    required String method,
    required String url,
    required dynamic body,
    required Map<String, dynamic>? queryParameters,
    required Map<String, dynamic> headers,
  }) {
    if (!kDebugMode) return;

    log('');
    log('════════════════════════════════════════════════════════════');
    log('🌐 API REQUEST');
    log('════════════════════════════════════════════════════════════');

    log('➡️ Method        : $method');
    log('➡️ URL           : $url');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      log('➡️ Query Params  : $queryParameters');
    } else {
      log('➡️ Query Params  : None');
    }

    log('➡️ Headers       : $headers');

    if (body != null) {
      if (body is FormData) {
        log('➡️ Request Body  : FormData');

        for (final field in body.fields) {
          log('   ${field.key}: ${field.value}');
        }

        for (final file in body.files) {
          log(
            '   ${file.key}: '
                '${file.value.filename ?? 'file'}',
          );
        }
      } else {
        log('➡️ Request Body  : $body');
      }
    } else {
      log('➡️ Request Body  : None');
    }

    log('════════════════════════════════════════════════════════════');
    log('');
  }

  /// Log API response details
  void _logResponse({
    required Response response,
    required int durationMs,
  }) {
    if (!kDebugMode) return;

    log('');
    log('════════════════════════════════════════════════════════════');
    log('✅ API RESPONSE');
    log('════════════════════════════════════════════════════════════');

    log('⬅️ Status Code   : ${response.statusCode}');
    log('⬅️ URL           : ${response.requestOptions.uri}');
    log('⬅️ Duration      : ${durationMs}ms');
    log('⬅️ Response      : ${response.data}');

    log('════════════════════════════════════════════════════════════');
    log('');
  }

  /// Log API error details
  void _logError({
    required DioException error,
    required String method,
    required String url,
    required int durationMs,
  }) {
    if (!kDebugMode) return;

    log('');
    log('════════════════════════════════════════════════════════════');
    log('❌ API ERROR');
    log('════════════════════════════════════════════════════════════');

    log('❌ Method        : $method');
    log('❌ URL           : $url');
    log('❌ Status Code   : ${error.response?.statusCode}');
    log('❌ Error Type    : ${error.type}');
    log('❌ Duration      : ${durationMs}ms');
    log('❌ Message       : ${error.message}');
    log('❌ Response      : ${error.response?.data}');

    if (error.requestOptions.queryParameters.isNotEmpty) {
      log(
        '❌ Query Params  : '
            '${error.requestOptions.queryParameters}',
      );
    }

    if (error.requestOptions.data != null) {
      log(
        '❌ Request Body  : '
            '${error.requestOptions.data}',
      );
    }

    log('════════════════════════════════════════════════════════════');
    log('');
  }

  // ---------------------------------------------------------------------------
  // GENERIC REQUEST
  // ---------------------------------------------------------------------------

  /// Generic request builder
  Future<dynamic> _request(
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
        requestOptions: RequestOptions(
          path: url,
          method: method,
        ),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final useJson = isFormData ? false : isJson;

      final body = isFormData
          ? (data is FormData
          ? data
          : FormData.fromMap(data ?? <String, dynamic>{}))
          : data;

      final headers = await _getHeaders(
        isJson: useJson,
      );

      final options = Options(
        headers: headers,
        method: method,
      );

      // Log request
      _logRequest(
        method: method,
        url: url,
        body: body,
        queryParameters: queryParameters,
        headers: headers,
      );

      // API request
      final response = await _dio.request(
        url,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );

      stopwatch.stop();

      // Log response
      _logResponse(
        response: response,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      return {
        'statusCode': response.statusCode,
        'data': _processResponseData(response.data),
      };
    } on DioException catch (e) {
      stopwatch.stop();

      // Log error
      _logError(
        error: e,
        method: method,
        url: url,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      // Handle connectivity errors
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        if (!hasInternet) {
          _showNoInternetDialog();
        } else {
          _showToast(
            'Unable to connect to server. Please try again later.',
          );
        }
      } else {
        _handleDioError(
          e,
          logoutOnUnauthorized: logoutOnUnauthorized,
        );
      }

      rethrow;
    } catch (e, stackTrace) {
      stopwatch.stop();

      if (kDebugMode) {
        log('');
        log('════════════════════════════════════════════════════════════');
        log('💥 UNEXPECTED API ERROR');
        log('════════════════════════════════════════════════════════════');
        log('Method   : $method');
        log('URL      : $url');
        log('Duration : ${stopwatch.elapsedMilliseconds}ms');
        log('Error    : $e');
        log('Stack    : $stackTrace');
        log('════════════════════════════════════════════════════════════');
        log('');
      }

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // HTTP METHODS
  // ---------------------------------------------------------------------------

  Future<dynamic> get(
      String url, {
        Map<String, dynamic>? queryParameters,
        bool isFormData = false,
      }) {
    return _request(
      'GET',
      url,
      queryParameters: queryParameters,
      isJson: true,
      isFormData: isFormData,
    );
  }

  Future<dynamic> post(
      String url, {
        dynamic data,
        bool isJson = true,
        bool isFormData = false,
        Map<String, dynamic>? queryParameters,
      }) {
    return _request(
      'POST',
      url,
      data: data,
      isJson: isJson,
      isFormData: isFormData,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> put(
      String url, {
        dynamic data,
        bool isJson = true,
        bool isFormData = false,
        Map<String, dynamic>? queryParameters,
      }) {
    return _request(
      'PUT',
      url,
      data: data,
      isJson: isJson,
      isFormData: isFormData,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> delete(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        bool isFormData = false,
      }) {
    return _request(
      'DELETE',
      url,
      data: data,
      isJson: true,
      isFormData: isFormData,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> patch(
      String url, {
        dynamic data,
        bool isJson = true,
        bool isFormData = false,
        Map<String, dynamic>? queryParameters,
      }) {
    return _request(
      'PATCH',
      url,
      data: data,
      isJson: isJson,
      isFormData: isFormData,
      queryParameters: queryParameters,
    );
  }

  // ---------------------------------------------------------------------------
  // RESPONSE PROCESSING
  // ---------------------------------------------------------------------------

  dynamic _processResponseData(dynamic data) {
    if (data is String) {
      if (data.isNotEmpty) {
        try {
          return json.decode(data);
        } on FormatException {
          return {
            'data': data,
          };
        }
      }

      return {};
    } else if (data is List) {
      return {
        'data': data,
      };
    } else {
      return data;
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------

  void _handleDioError(
      DioException e, {
        bool logoutOnUnauthorized = true,
      }) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    String errorMessage = 'An unexpected error occurred';

    if (responseData is Map && responseData['message'] != null) {
      errorMessage = responseData['message'].toString();
    } else if (e.message != null) {
      errorMessage = e.message!;
    }

    if (kDebugMode) {
      log('API Error Status Code: $statusCode');
      log('API Error Message: $errorMessage');
      log('API Error Response: ${e.response?.data}');
    }

    // Maintenance mode
    if (statusCode == 1999 ||
        (responseData is Map &&
            responseData['statusCode'] == 1999)) {
      _redirectToMaintenanceMode(errorMessage);
      return;
    }

    // Unauthorized
    if (statusCode == 401) {
      if (logoutOnUnauthorized) {
        getx.Get.defaultDialog(
          title: 'Session expired',
          middleText: 'Please log in again.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          onConfirm: () {
            _authManager.logoutUser();
            // TODO:
            // getx.Get.offAll(() => LoginScreen());
          },
        );
      } else {
        _showToast(errorMessage);
      }

      return;
    }

    // Other errors
    // _showToast(errorMessage);
  }

  // ---------------------------------------------------------------------------
  // TOAST
  // ---------------------------------------------------------------------------

  void _showToast(String message) {
    getx.Get.snackbar(
      'Server Error',
      'Something went wrong please try later',
      snackPosition: getx.SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      borderRadius: 8.0,
      duration: const Duration(seconds: 3),
      isDismissible: true,
    );
  }

  // ---------------------------------------------------------------------------
  // GET DIO INSTANCE
  // ---------------------------------------------------------------------------

  Dio get dio => _dio;
}*/
