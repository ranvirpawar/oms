// services/bag_service.dart


import 'package:lifenity_connect/network/app_urls.dart';



import '../../../../network/api_client.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
// for debugPrint

import 'package:get/get.dart';
class BagService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<Map<String, dynamic>> insertStartQRCodeBagEvent({
    required String bagCode,
    required String processId,
    required String facilityCode,
    required int userId,
  }) async {
    try {
      final body = {
        'Bagcode': bagCode,
        'processid': processId.toString(),
        'facilitycode': facilityCode,
        'userid': userId.toString(),
      };

      kPrint('🧾 InsertStartQRCodeBegEvent...');
      kPrint(
        '➡️ URL: ${AppUrls.insertStartQRCodeBagEvent} | Body: $body',
      );

      final response = await apiClient.post(
        AppUrls.insertStartQRCodeBagEvent,
        data: body,
      );

      kPrint('📥 Response: ${response.body}');

      return response.body;
    } catch (e) {
      kPrint('❌ Error in insertStartQRCodeBagEvent: $e');
      throw Exception('Error: $e');
    }
  }
}

