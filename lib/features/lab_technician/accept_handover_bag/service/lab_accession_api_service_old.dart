
import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/model/bag_model.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';

import '../../../../utils/helper_functions/helper_methods.dart'; // Required for debugPrint
import 'package:get/get.dart';
class LabAccessionService {
  final APIClient apiClient = Get.find<APIClient>();

  // Get Bag Transaction Details
  Future<BagTransactionResponse> getScanQRForAndTransactionID({
    required String bagcode,
    required String processid,
    required String userid,
  }) async {
    final body = {
      'Bagcode': bagcode,
      'Processid': processid,
      'userid': userid,
    };

    kPrint(
      '🚀 [LabAccessionService] Starting getScanQRForAndTransactionID...',
    );
    kPrint(
      '📝 [LabAccessionService] Request URL: '
          '${AppUrls.getScanQRForAndTransactionID}',
    );
    kPrint('📤 [LabAccessionService] Request Body: $body');

    try {
      final response = await apiClient.post(
        AppUrls.getScanQRForAndTransactionID,
        data: body,
      );

      kPrint(
        '📥 [LabAccessionService] Response: ${response.body}',
      );

      kPrint(
        '✅ [LabAccessionService] Success! '
            'Parsing BagTransactionResponse...',
      );

      return BagTransactionResponse.fromJson(response.body);
    } catch (e) {
      kPrint(
        '💥 [LabAccessionService] Network error during fetch: $e',
      );
      throw Exception('Network error: $e');
    }
  }

  // ---

  // Insert/Update Bag Transaction Status
  Future<StatusUpdateResponse> insertBagTransactionStatus({
    required String transactionID,
    required String processid,
    required String userid,
    required String lats,
    required String longs,
    required String handOverUserid,
  }) async {
    final body = {
      'TransactionID': transactionID,
      'processid': processid,
      'USerid': userid,
      'lats': lats,
      'longs': longs,
      'HandOverUserid': handOverUserid,
    };

    kPrint(
      '🚀 [LabAccessionService] Starting insertBagTransactionStatus...',
    );
    kPrint(
      '📝 [LabAccessionService] Request URL: '
          '${AppUrls.insertBagTransactionStatus}',
    );
    kPrint('📤 [LabAccessionService] Request Body: $body');

    try {
      final response = await apiClient.post(
        AppUrls.insertBagTransactionStatus,
        data: body,
      );

      kPrint(
        '📥 [LabAccessionService] Response: ${response.body}',
      );

      kPrint(
        '✅ [LabAccessionService] Success! '
            'Parsing StatusUpdateResponse...',
      );

      return StatusUpdateResponse.fromJson(response.body);
    } catch (e) {
      kPrint(
        '💥 [LabAccessionService] Network error during update: $e',
      );
      throw Exception('Network error: $e');
    }
  }
}

/*class LabAccessionService {

  // Get Bag Transaction Details
  Future<BagTransactionResponse> getScanQRForAndTransactionID({
    required String bagcode,
    required String processid,
    required String userid,
  }) async {
    final body = {
      'Bagcode': bagcode,
      'Processid': processid,
      'userid': userid,
    };

    debugPrint('🚀 [LabAccessionService] Starting getScanQRForAndTransactionID...');
    debugPrint('📝 [LabAccessionService] Request URL: ${AppUrls.getScanQRForAndTransactionID}');
    debugPrint('📤 [LabAccessionService] Request Body: $body');

    try {
      final response = await http.post(
        Uri.parse(AppUrls.getScanQRForAndTransactionID),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [LabAccessionService] Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [LabAccessionService] Success! Parsing BagTransactionResponse...');
        // debugPrint('📄 [LabAccessionService] Raw Response: ${response.body}'); // Uncomment for full response body
        final jsonData = json.decode(response.body);
        return BagTransactionResponse.fromJson(jsonData);
      } else {
        debugPrint('❌ [LabAccessionService] Failed to fetch bag details: HTTP ${response.statusCode}');
        throw Exception('Failed to fetch bag details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 [LabAccessionService] Network error during fetch: $e');
      throw Exception('Network error: $e');
    }
  }

  // ---

  // Insert/Update Bag Transaction Status
  Future<StatusUpdateResponse> insertBagTransactionStatus({
    required String transactionID,
    required String processid,
    required String userid,
    required String lats,
    required String longs,
    required String handOverUserid,
  }) async {
    final body = {
      'TransactionID': transactionID,
      'processid': processid,
      'USerid': userid,
      'lats': lats,
      'longs': longs,
      'HandOverUserid': handOverUserid,
    };

    debugPrint('🚀 [LabAccessionService] Starting insertBagTransactionStatus...');
    debugPrint('📝 [LabAccessionService] Request URL: ${AppUrls.insertBagTransactionStatus}');
    debugPrint('📤 [LabAccessionService] Request Body: $body');

    try {
      final response = await http.post(
        Uri.parse(AppUrls.insertBagTransactionStatus),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 [LabAccessionService] Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [LabAccessionService] Success! Parsing StatusUpdateResponse...');
        // debugPrint('📄 [LabAccessionService] Raw Response: ${response.body}'); // Uncomment for full response body
        final jsonData = json.decode(response.body);
        return StatusUpdateResponse.fromJson(jsonData);
      } else {
        debugPrint('❌ [LabAccessionService] Failed to update status: HTTP ${response.statusCode}');
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 [LabAccessionService] Network error during update: $e');
      throw Exception('Network error: $e');
    }
  }
}*/





