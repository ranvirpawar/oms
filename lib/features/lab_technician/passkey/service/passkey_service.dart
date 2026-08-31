import 'dart:convert';


import 'package:get/get.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';


import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/passkey_model.dart';
import 'package:lifenity_connect/utils/helper_functions/debug_print.dart';

// Service
class PasskeyService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<PasskeyResponse> getPassKey(String userId) async {
    try {
      kPrint('Request URL: ${AppUrls.getPassKey}');

      final response = await apiClient.post(
        AppUrls.getPassKey,
        data: {
          'Userid': userId,
        },
      );

      kPrint(response.body.toString());

      return PasskeyResponse.fromJson(response.body);
    } catch (e) {
      throw Exception('Error fetching passkey: $e');
    }
  }
}
