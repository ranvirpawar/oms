import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';

import '../controller/splash_screen_controller.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});

  final SplashController controller = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(AppAssets.splashBg, fit: BoxFit.cover),

          // logo
          Positioned(top: 60, right: 50, left: 50, child: Center(child: Image.asset(AppAssets.lifenityLogo, height: 200, width: 200))),
        ],
      ),
    );
  }
}
