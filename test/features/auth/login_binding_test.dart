import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/controller/login_controller.dart';
import 'package:lifenity_connect/features/auth/service/login_service.dart';
import 'package:lifenity_connect/features/auth/view/login_screen.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/network/session_coordinator.dart';
import 'package:lifenity_connect/features/auth/binding/login_binding.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    // Prerequisites that exist app-wide at startup (main.dart / beta_main.dart).
    final authManager = AuthManager();
    Get.put(authManager);
    Get.put(SessionCoordinator(authManager));
    Get.put(
      APIClient(
        dio: Dio(),
        sessionManager: Get.find<SessionCoordinator>(),
      ),
    );
  });

  tearDown(() => Get.reset());

  test('LoginBinding registers the LoginService and LoginController factories',
      () {
    LoginBinding().dependencies();

    expect(Get.isRegistered<LoginService>(), isTrue);
    expect(Get.isRegistered<LoginController>(), isTrue);
  });

  test('LoginController resolves all of its dependencies through the binding',
      () {
    LoginBinding().dependencies();

    final controller = Get.find<LoginController>();
    expect(controller, isA<LoginController>());

    // The controller pulls LoginService out of the container (Get.find), so a
    // single instance is shared instead of a second Get.put registration.
    expect(Get.find<LoginService>(), isA<LoginService>());
    expect(identical(controller, Get.find<LoginController>()), isTrue);
  });

  testWidgets('LoginScreenView is buildable when navigated with LoginBinding',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Get.offAll(
                  () => const LoginScreenView(),
                  binding: LoginBinding(),
                ),
                child: const Text('launch login'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('launch login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // fadeIn transition

    expect(find.byType(LoginScreenView), findsOneWidget);
    expect(Get.find<LoginController>(), isA<LoginController>());
  });
}