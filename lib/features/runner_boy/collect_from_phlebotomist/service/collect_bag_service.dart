// services/collect_bag_service.dart

import 'package:get/get.dart';

import 'package:lifenity_connect/network/app_urls.dart';
import '../../../../constants/bag_process_ids.dart';
import '../../../../network/api_client.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/helper_functions/helper_methods.dart';

class CollectBagService {
  final UserService userService = Get.find<UserService>();
  final APIClient apiClient = Get.find<APIClient>();

  /// Step 1 (Both flows): Scan bag & get details
  /// GETQRBagCount — type=1 for phlebotomist module
  Future<Map<String, dynamic>> getQRBagCount({
    required int type,
    required String bagcode,
  }) async {
    try {
      kPrint('📦 GETQRBagCount | bagcode: $bagcode | type: $type');
      kPrint(AppUrls.getQRBagCount);

      final response = await apiClient.post(
        AppUrls.getQRBagCount,
        data: {
          'type': '$type', //  1 for collect, 2 for transfer
          'Bagcode': bagcode,
        },
      );

      kPrint('📥 Response: ${response.body}');

      return response.body;
    } catch (e) {
      kPrint('❌ Error in getQRBagCount: $e');
      throw Exception('Error: $e');
    }
  }

  /// Step 2 (Collect flow): Collect whole bag from phlebotomist
  /// InsertQRBagSession_Event — processid = wholebagCollected (5)
  Future<Map<String, dynamic>> collectBag({
    required int sessionId,
    required int userId,
  }) async {
    try {
      kPrint('✅ CollectBag | sessionId: $sessionId, userId: $userId');
      kPrint(AppUrls.insertQRBagSessionEvent);

      final response = await apiClient.post(
        AppUrls.insertQRBagSessionEvent,
        data: {
          'sessionid': sessionId.toString(),
          'processid': BagProcessId.wholeBagCollected.processId,
          'userid': userId.toString(),
        },
      );

      kPrint('📥 Response: ${response.body}');

      return response.body;
    } catch (e) {
      kPrint('❌ Error in collectBag: $e');
      throw Exception('Error: $e');
    }
  }

  /// Step 3 (Transfer flow): Transfer samples source → destination
  /// InsertTransferSample_to_QRBag
  Future<Map<String, dynamic>> transferSampleToQRBag({
    required int fromSession,
    required int toSession,
    required int fromBagId,
    required int toBagId,
    required int userId,
    required int tubecount,
  }) async {
    try {
      kPrint('🔄 TransferSample | from: $fromSession → to: $toSession');
      kPrint(AppUrls.transferBag);

      final body = {
        'FromSession': fromSession.toString(),
        'ToSession': toSession.toString(),
        'Frombagid': fromBagId.toString(),
        'Tobagid': toBagId.toString(),
        'userid': userId.toString(),
        'tubecount': tubecount.toString(),
      };

      kPrint('🔄 Body: $body');

      final response = await apiClient.post(
        AppUrls.transferBag,
        data: body,
      );

      kPrint('📥 Response: ${response.body}');

      return response.body;
    } catch (e) {
      kPrint('❌ Error in transferSampleToQRBag: $e');
      throw Exception('Error: $e');
    }
  }
}/*class CollectBagService {
  final UserService userService = Get.find<UserService>();

  /// Step 1 (Both flows): Scan bag & get details
  /// GETQRBagCount — type=1 for phlebotomist module
  Future<Map<String, dynamic>> getQRBagCount({
    required int type,
    required String bagcode,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.getQRBagCount);
      debugPrint('📦 GETQRBagCount | bagcode: $bagcode | type: $type');
      debugPrint(uri.toString());

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'type': '$type', //  1 for collect, 2 for transfer
          'Bagcode': bagcode,
        },
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to get bag count');
    } catch (e) {
      debugPrint('❌ Error in getQRBagCount: $e');
      throw Exception('Error: $e');
    }
  }

  /// Step 2 (Collect flow): Collect whole bag from phlebotomist
  /// InsertQRBagSession_Event — processid = wholebagCollected (5)
  Future<Map<String, dynamic>> collectBag({
    required int sessionId,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.insertQRBagSessionEvent);
      debugPrint('✅ CollectBag | sessionId: $sessionId, userId: $userId');
      debugPrint(uri.toString());

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'sessionid': sessionId.toString(),
          'processid': BagProcessId.wholeBagCollected.processId,
          'userid': userId.toString(),
        },
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to collect bag');
    } catch (e) {
      debugPrint('❌ Error in collectBag: $e');
      throw Exception('Error: $e');
    }
  }

  /// Step 3 (Transfer flow): Transfer samples source → destination
  /// InsertTransferSample_to_QRBag
  Future<Map<String, dynamic>> transferSampleToQRBag({
    required int fromSession,
    required int toSession,
    required int fromBagId,
    required int toBagId,
    required int userId,
    required int tubecount,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.transferBag);
      debugPrint('🔄 TransferSample | from: $fromSession → to: $toSession');
      debugPrint(uri.toString());
      final body = {
        'FromSession': fromSession.toString(),
        'ToSession': toSession.toString(),
        'Frombagid': fromBagId.toString(),
        'Tobagid': toBagId.toString(),
        'userid': userId.toString(),
        'tubecount': tubecount.toString(),
      };
      debugPrint('🔄 Body: $body');


      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to transfer samples');
    } catch (e) {
      debugPrint('❌ Error in transferSampleToQRBag: $e');
      throw Exception('Error: $e');
    }
  }
}*/
