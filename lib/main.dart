import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_strings.dart';
import 'package:lifenity_connect/features/auth/view/splash_screen.dart';
import 'package:lifenity_connect/network/app_urls.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/theme/app_theme.dart';
import 'package:lifenity_connect/theme/theme_provider.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart';

import 'features/dashboard/dashboard_controller/dashboard_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await AppTheme.initialize();
  Get.put(ThemeProvider());
  Get.put(AuthManager());
  AppUrls.setEnvironment(Environment.live);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.to;
    return ProviderScope(
      child: GetMaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeProvider.to.lightTheme,
        navigatorKey: LiquidSnack.navigatorKey,
        navigatorObservers: [DashboardRouteObserver.instance],
      
        home: SplashScreen(),
      ),
    );
  }
}
