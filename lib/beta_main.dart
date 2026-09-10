import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/services/app_envirionment_service.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/theme/app_theme.dart';
import 'package:lifenity_connect/theme/theme_provider.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart';

import 'features/auth/view/splash_screen.dart';
import 'features/dashboard/dashboard_controller/dashboard_controller.dart';
import 'network/app_urls.dart';
import 'network/session_coordinator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Beta Environment
  AppUrls.setEnvironment(Environment.beta);
  AppEnvironment.setBeta();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AppTheme.initialize();
  Get.put(ThemeProvider());
  Get.put(AuthManager());
  final sessionCoordinator = SessionCoordinator(Get.find<AuthManager>());
  Get.put(sessionCoordinator);
  Get.put(APIClient(
    dio: Dio(),
    sessionManager: Get.find<SessionCoordinator>(),
  ));
  _wireSessionExpiryHandling(sessionCoordinator);
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

/// The app-shell's SINGLE subscriber of session-expiry events.
///
/// [SessionCoordinator] emits [SessionExpired] exactly once when a 401 is
/// seen (handled inside `APIClient`, which never touches the UI itself).
/// Everything the user sees for a dead session — the one "Session expired,
/// please login again" message — originates here, so it happens exactly
/// once no matter how many parallel requests hit 401 at the same moment.
///
/// Screens must swallow `AppError.isSessionTerminal` errors (see the
/// guards in controllers) so this is the only toast rendered on 401.
/// Navigation to Login is performed by `AuthManager.logoutUser()` →
/// `RouteManager.redirectToLogin()`, which [SessionCoordinator] already
/// invokes as part of the teardown.
void _wireSessionExpiryHandling(SessionCoordinator coordinator) {
  coordinator.events.listen((event) {
    if (event is! SessionExpired) return;

    // Run after the current frame so the navigator's Overlay (used by
    // LiquidSnack) is guaranteed to exist when we insert the toast.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LiquidSnack.error(
        'Your session has expired. Please login again.',
        title: 'Session expired',
      );
    });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: GetMaterialApp(
        navigatorObservers: [DashboardRouteObserver.instance],
        navigatorKey: LiquidSnack.navigatorKey,
        title: 'OMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeProvider.to.lightTheme,
        home: SplashScreen(),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
