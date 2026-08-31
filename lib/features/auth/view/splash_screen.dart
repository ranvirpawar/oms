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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // logo
            Center(
              child: Image.asset(
                AppAssets.lifenityLogo,
                height: 200,
                width: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
