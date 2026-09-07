import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../controller/splash_screen_controller.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final SplashController controller = Get.put(SplashController());

  late final AnimationController _animController;
  late final Animation<double> _bgFade;
  late final Animation<double> _bgScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Background fades + settles in first
    _bgFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _bgScale = Tween<double>(begin: 1.06, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Logo fades + slides up slightly after
    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image, edge-to-edge, fades + settles in
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _bgFade.value,
                child: Transform.scale(
                  scale: _bgScale.value,
                  child: child,
                ),
              );
            },
            child: RepaintBoundary(
              child: Image.asset(
                AppAssets.splashScreen,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Lifenity logo positioned at 30% from the top
          Positioned(
            top: size.height * 0.30,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _logoSlide,
              child: FadeTransition(
                opacity: _logoFade,
                child: Center(
                  child: Image.asset(
                    AppAssets.lifenityLogo,
                    width: 160,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}