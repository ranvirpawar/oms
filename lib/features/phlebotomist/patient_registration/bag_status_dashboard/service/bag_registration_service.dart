
import 'package:get/get.dart';

import '../../../../../network/api_client.dart';
import '../../../../../network/app_urls.dart';
import '../../../../../utils/helper_functions/helper_methods.dart';

class BagRegistrationService {
  final APIClient _apiClient = Get.find<APIClient>();

  /// API 1: Get currently open bag session for user
  Future<Map<String, dynamic>> getUserwiseQRBagSession(int userId) async {
    try {
      kPrint('📦 GetUserwiseQRBagSession...');
      kPrint(
        '➡️ URL: ${AppUrls.getUserwiseQRBagSession} | Body: {Userid: $userId}',
      );

      final result = await _apiClient.post(
        AppUrls.getUserwiseQRBagSession,
        data: {'Userid': userId.toString()},
      );

      kPrint('📥 Response (${result.statusCode}): ${result.data}');

      return result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
    } catch (e) {
      kPrint('❌ Error in getUserwiseQRBagSession: $e');
      throw Exception('Error: $e');
    }
  }

  /// API 2: Get detailed bag info (capacity, count, vacant space)
  Future<Map<String, dynamic>> getQRBagDetails({
    required int sessionId,
    required int bagId,
  }) async {
    try {
      kPrint('🔢 Proc_GetQRBagDetails...');
      kPrint(
        '➡️ URL: ${AppUrls.getQRBagDetails} | Body: {Sessionid: $sessionId, Bagid: $bagId}',
      );

      final result = await _apiClient.post(
        AppUrls.getQRBagDetails,
        data: {'Sessionid': sessionId.toString(), 'Bagid': bagId.toString()},
      );

      kPrint('📥 Response (${result.statusCode}): ${result.data}');

      return result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
    } catch (e) {
      kPrint('❌ Error in getQRBagDetails: $e');
      throw Exception('Error: $e');
    }
  }

  /// API 3 Open bag (processid=2)
  Future<Map<String, dynamic>> insertStartQRCodeBagEvent({
    required String bagcode,
    required int processId,
    required String facilityCode,
    required int userId,
  }) async {
    try {
      kPrint('🧾 InsertStartQRCodeBegEvent...');
      kPrint(
        '➡️ URL: ${AppUrls.insertStartQRCodeBagEvent} | Body: {Bagcode: $bagcode, processid: $processId, facilitycode: $facilityCode, userid: $userId}',
      );

      final result = await _apiClient.post(
        AppUrls.insertStartQRCodeBagEvent,
        data: {
          'Bagcode': bagcode,
          'processid': processId.toString(),
          'facilitycode': facilityCode,
          'userid': userId.toString(),
        },
      );

      kPrint('📥 Response (${result.statusCode}): ${result.data}');

      return result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
    } catch (e) {
      kPrint('❌ Error in insertStartQRCodeBagEvent: $e');
      throw Exception('Error: $e');
    }
  }

  /// Close bag — InsertQRBagSession_Event
  Future<Map<String, dynamic>> insertQRBagSessionEvent({
    required int sessionId,
    required int processId,
    required int userId,
  }) async {
    try {
      kPrint('🔒 InsertQRBagSession_Event...');
      kPrint(
        '➡️ URL: ${AppUrls.insertQRBagSessionEvent} | Body: {sessionid: $sessionId, processid: $processId, userid: $userId}',
      );

      final result = await _apiClient.post(
        AppUrls.insertQRBagSessionEvent,
        data: {
          'sessionid': sessionId.toString(),
          'processid': processId.toString(),
          'userid': userId.toString(),
        },
      );

      kPrint('📥 Response (${result.statusCode}): ${result.data}');

      return result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
    } catch (e) {
      kPrint('❌ Error in insertQRBagSessionEvent: $e');
      throw Exception('Error: $e');
    }
  }

  /// GetActiveQRBagSessions
  Future<Map<String, dynamic>> getActiveQRBagSessions(int userId) async {
    try {
      kPrint('📦 GetActiveQRBagSessions | userid: $userId');

      final result = await _apiClient.post(
        AppUrls.getActiveQRBagSessions,
        data: {'Userid': userId.toString()},
      );

      kPrint('📥 Response (${result.statusCode}): ${result.data}');

      return result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
    } catch (e) {
      kPrint('❌ Error in getActiveQRBagSessions: $e');
      throw Exception('Error: $e');
    }
  }

  /// GetRegistrationDetails_QRBag
  Future<Map<String, dynamic>> getRegistrationDetailsQRBag({
    required int sessionId,
    required int bagId,
  }) async {
    try {
      kPrint(
        '📋 GetRegistrationDetails_QRBag | sessionid: $sessionId, bagid: $bagId',
      );

      final result = await _apiClient.post(
        AppUrls.getRegistrationDetailsQRBag,
        data: {'sessionid': sessionId.toString(), 'bagid': bagId.toString()},
      );

      kPrint('📥 Response (${result.statusCode}): ${result.data}');

      return result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : result.body;
    } catch (e) {
      kPrint('❌ Error in getRegistrationDetailsQRBag: $e');
      throw Exception('Error: $e');
    }
  }
}

/*class BagRegistrationService {

  /// API 1: Get currently open bag session for user
  Future<Map<String, dynamic>> getUserwiseQRBagSession(int userId) async {
    try {
      final uri = Uri.parse(AppUrls.getUserwiseQRBagSession);
      debugPrint('📦 GetUserwiseQRBagSession...');
      debugPrint('➡️ URL: $uri | Body: {Userid: $userId}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'Userid': userId.toString()},
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get bag session');
    } catch (e) {
      debugPrint('❌ Error in getUserwiseQRBagSession: $e');
      throw Exception('Error: $e');
    }
  }

  /// API 2: Get detailed bag info (capacity, count, vacant space)
  Future<Map<String, dynamic>> getQRBagDetails({
    required int sessionId,
    required int bagId,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.getQRBagDetails);
      debugPrint('🔢 Proc_GetQRBagDetails...');
      debugPrint('➡️ URL: $uri | Body: {Sessionid: $sessionId, Bagid: $bagId}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'Sessionid': sessionId.toString(),
          'Bagid': bagId.toString(),
        },
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get bag details');
    } catch (e) {
      debugPrint('❌ Error in getQRBagDetails: $e');
      throw Exception('Error: $e');
    }
  }

  /// API 3 Open bag (processid=2)
  Future<Map<String, dynamic>> insertStartQRCodeBagEvent({
    required String bagcode,
    required int processId,
    required String facilityCode,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.insertStartQRCodeBagEvent);
      debugPrint('🧾 InsertStartQRCodeBegEvent...');
      debugPrint('➡️ URL: $uri | Body: {Bagcode: $bagcode, processid: $processId, facilitycode: $facilityCode, userid: $userId}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'Bagcode': bagcode,
          'processid': processId.toString(),
          'facilitycode': facilityCode,
          'userid': userId.toString(),
        },
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to insert bag event');
    } catch (e) {
      debugPrint('❌ Error in insertStartQRCodeBagEvent: $e');
      throw Exception('Error: $e');
    }
  }
  /// Close bag — InsertQRBagSession_Event
  Future<Map<String, dynamic>> insertQRBagSessionEvent({
    required int sessionId,
    required int processId,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.insertQRBagSessionEvent);
      debugPrint('🔒 InsertQRBagSession_Event...');
      debugPrint('➡️ URL: $uri | Body: {sessionid: $sessionId, processid: $processId, userid: $userId}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'sessionid': sessionId.toString(),
          'processid': processId.toString(),
          'userid': userId.toString(),
        },
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to insert bag session event');
    } catch (e) {
      debugPrint('❌ Error in insertQRBagSessionEvent: $e');
      throw Exception('Error: $e');
    }
  }
  /// GetActiveQRBagSessions
  Future<Map<String, dynamic>> getActiveQRBagSessions(int userId) async {
    try {
      final uri = Uri.parse(AppUrls.getActiveQRBagSessions);
      debugPrint('📦 GetActiveQRBagSessions | userid: $userId');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'Userid': userId.toString()},
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to get active bag sessions');
    } catch (e) {
      debugPrint('❌ Error in getActiveQRBagSessions: $e');
      throw Exception('Error: $e');
    }
  }

  /// GetRegistrationDetails_QRBag
  Future<Map<String, dynamic>> getRegistrationDetailsQRBag({
    required int sessionId,
    required int bagId,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.getRegistrationDetailsQRBag);
      debugPrint('📋 GetRegistrationDetails_QRBag | sessionid: $sessionId, bagid: $bagId');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'sessionid': sessionId.toString(),
          'bagid': bagId.toString(),
        },
      );

      debugPrint('📥 Response (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to get registration details');
    } catch (e) {
      debugPrint('❌ Error in getRegistrationDetailsQRBag: $e');
      throw Exception('Error: $e');
    }
  }
}*/
