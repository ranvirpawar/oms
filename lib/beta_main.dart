import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/services/app_envirionment_service.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/theme/app_theme.dart';
import 'package:lifenity_connect/theme/theme_provider.dart';

import 'features/auth/view/splash_screen.dart';
import 'features/dashboard/dashboard_controller/dashboard_controller.dart';
import 'network/app_urls.dart';

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
  Get.put(APIClient());
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: GetMaterialApp(
        navigatorObservers: [DashboardRouteObserver.instance],
        title: 'Lifenity Connect Beta',
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
