// lib/features/lab_technician/accept_bag_in_lab/service/lab_accession_api_service_old.dart


import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/bag_details_extended_model.dart';
import '../model/bag_model_new.dart';
import 'package:get/get.dart';
class LabAccessionService {
  static const _tag = '[LabAccessionService]';

  final APIClient apiClient = Get.find<APIClient>();

  // ─── Step 1: Scan QR → get SessionID ────────────────────────────────────────
  /// POST /GETScanQRBag
  /// Body: { "Bagcode": bagcode }
  Future<ScanQRBagResponse> scanQRBag({required String bagcode}) async {
    final body = {'Bagcode': bagcode};

    kPrint('🚀 $_tag scanQRBag → ${AppUrls.getScanQRBag}');
    kPrint('📤 $_tag Body: $body');

    try {
      final response = await apiClient.post(AppUrls.getScanQRBag, data: body);

      kPrint('📥 $_tag Response: ${response.body}');
      kPrint('✅ $_tag scanQRBag success');

      return ScanQRBagResponse.fromJson(response.body);
    } catch (e) {
      kPrint('💥 $_tag Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ─── Step 2: Get bag details for lab team ───────────────────────────────────
  /// POST /Proc_GetQRBagDetails_ForLabTeam
  /// Body: { "SessionID": sessionId, "facilitycode": facilityCode }
  Future<BagDetailsForLabResponse> getBagDetailsForLabTeam({
    required String sessionId,
    required String facilityCode,
  }) async {
    final body = {'type': '1', 'SessionID': sessionId, 'facilitycode': '0'};

    kPrint(
      '🚀 $_tag getBagDetailsForLabTeam → '
      '${AppUrls.getBagDetailsForLabTeam}',
    );
    kPrint('📤 $_tag Body: $body');

    try {
      final response = await apiClient.post(
        AppUrls.getBagDetailsForLabTeam,
        data: body,
      );

      kPrint('📥 $_tag Response: ${response.body}');
      kPrint('✅ $_tag getBagDetailsForLabTeam success');

      return BagDetailsForLabResponse.fromJson(response.body);
    } catch (e) {
      kPrint('💥 $_tag Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ─── Step 2b: Get facility list (type=2) ─────────────────────────────────────
  /// POST /Proc_GetQRBagDetails_ForLabTeam
  /// Body: { "type": "2", "SessionID": sessionId, "facilitycode": "0" }
  Future<BagFacilityListResponse> getBagFacilityList({
    required String sessionId,
  }) async {
    final body = {'type': '2', 'SessionID': sessionId, 'facilitycode': '0'};

    kPrint(
      '🚀 $_tag getBagFacilityList → '
      '${AppUrls.getBagDetailsForLabTeam}',
    );
    kPrint('📤 $_tag Body: $body');

    try {
      final response = await apiClient.post(
        AppUrls.getBagDetailsForLabTeam,
        data: body,
      );

      kPrint('📥 $_tag getBagFacilityList response: ${response.body}');

      return BagFacilityListResponse.fromJson(response.body);
    } catch (e) {
      kPrint('💥 $_tag getBagFacilityList error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ─── Step 2c: Get patient list (type=4) ──────────────────────────────────────
  /// POST /Proc_GetQRBagDetails_ForLabTeam
  /// Body: { "type": "4", "SessionID": sessionId, "facilitycode": "0" }
  Future<BagPatientListResponse> getBagPatientList({
    required String sessionId,
  }) async {
    final body = {'type': '4', 'SessionID': sessionId, 'facilitycode': '0'};

    kPrint(
      '🚀 $_tag getBagPatientList → '
      '${AppUrls.getBagDetailsForLabTeam}',
    );
    kPrint('📤 $_tag Body: $body');

    try {
      final response = await apiClient.post(
        AppUrls.getBagDetailsForLabTeam,
        data: body,
      );

      kPrint('📥 $_tag getBagPatientList response: ${response.body}');

      return BagPatientListResponse.fromJson(response.body);
    } catch (e) {
      kPrint('💥 $_tag getBagPatientList error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ─── Step 3: Accept bag (insert session event) ──────────────────────────────
  /// POST /InsertQRBagSession_Event
  /// Body: { "sessionid": sessionId, "processid": "8", "userid": userId }
  Future<BagSessionEventResponse> insertQRBagSessionEvent({
    required String sessionId,
    required String userId,
    String processId = '8',
  }) async {
    final body = {
      'sessionid': sessionId,
      'processid': processId,
      'userid': userId,
    };

    kPrint(
      '🚀 $_tag insertQRBagSessionEvent → '
      '${AppUrls.insertQRBagSessionEvent}',
    );
    kPrint('📤 $_tag Body: $body');

    try {
      final response = await apiClient.post(
        AppUrls.insertQRBagSessionEvent,
        data: body,
      );

      kPrint('📥 $_tag Response: ${response.body}');
      kPrint('✅ $_tag insertQRBagSessionEvent success');

      return BagSessionEventResponse.fromJson(response.body);
    } catch (e) {
      kPrint('💥 $_tag Network error: $e');
      throw Exception('Network error: $e');
    }
  }
}

/*class LabAccessionService {
  static const _tag = '[LabAccessionService]';

  // ─── Step 1: Scan QR → get SessionID ────────────────────────────────────────
  /// POST /GETScanQRBag
  /// Body: { "Bagcode": bagcode }
  Future<ScanQRBagResponse> scanQRBag({
    required String bagcode,
  }) async {
    final body = {'Bagcode': bagcode};

    debugPrint('🚀 $_tag scanQRBag → ${AppUrls.getScanQRBag}');
    debugPrint('📤 $_tag Body: $body');

    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.getScanQRBag),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 $_tag Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ $_tag scanQRBag success');
        final jsonData = json.decode(response.body);
        return ScanQRBagResponse.fromJson(jsonData);
      } else {
        debugPrint('❌ $_tag HTTP ${response.statusCode}');
        throw Exception('Failed to scan bag QR: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 $_tag Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ─── Step 2: Get bag details for lab team ───────────────────────────────────
  /// POST /Proc_GetQRBagDetails_ForLabTeam
  /// Body: { "SessionID": sessionId, "facilitycode": facilityCode }
  Future<BagDetailsForLabResponse> getBagDetailsForLabTeam({
    required String sessionId,
    required String facilityCode,
  }) async {
    final body = {
      'type': '1',
      'SessionID': sessionId,
      'facilitycode': '0',
    };

    debugPrint('🚀 $_tag getBagDetailsForLabTeam → ${AppUrls.getBagDetailsForLabTeam}');
    debugPrint('📤 $_tag Body: $body');

    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.getBagDetailsForLabTeam),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 $_tag Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ $_tag getBagDetailsForLabTeam success');
        final jsonData = json.decode(response.body);
        return BagDetailsForLabResponse.fromJson(jsonData);
      } else {
        debugPrint('❌ $_tag HTTP ${response.statusCode}');
        throw Exception('Failed to get bag details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 $_tag Network error: $e');
      throw Exception('Network error: $e');
    }
  }

// ─── Step 2b: Get facility list (type=2) ─────────────────────────────────────
  /// POST /Proc_GetQRBagDetails_ForLabTeam
  /// Body: { "type": "2", "SessionID": sessionId, "facilitycode": "0" }
  Future<BagFacilityListResponse> getBagFacilityList({
    required String sessionId,
  }) async {
    final body = {
      'type': '2',
      'SessionID': sessionId,
      'facilitycode': '0',
    };

    debugPrint('🚀 $_tag getBagFacilityList → ${AppUrls.getBagDetailsForLabTeam}');
    debugPrint('📤 $_tag Body: $body');

    try {
      final response = await http
          .post(
        Uri.parse(AppUrls.getBagDetailsForLabTeam),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 $_tag getBagFacilityList status: ${response.statusCode}');
      debugPrint('📥 $_tag getBagFacilityList body: ${response.body}');


      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return BagFacilityListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to get facility list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 $_tag getBagFacilityList error: $e');
      throw Exception('Network error: $e');
    }
  }

// ─── Step 2c: Get patient list (type=4) ──────────────────────────────────────
  /// POST /Proc_GetQRBagDetails_ForLabTeam
  /// Body: { "type": "4", "SessionID": sessionId, "facilitycode": "0" }
  Future<BagPatientListResponse> getBagPatientList({
    required String sessionId,
  }) async {
    final body = {
      'type': '4',
      'SessionID': sessionId,
      'facilitycode': '0',
    };

    debugPrint('🚀 $_tag getBagPatientList → ${AppUrls.getBagDetailsForLabTeam}');
    debugPrint('📤 $_tag Body: $body');

    try {
      final response = await http
          .post(
        Uri.parse(AppUrls.getBagDetailsForLabTeam),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 $_tag getBagPatientList status: ${response.statusCode}');
      debugPrint('📥 $_tag getBagPatientList body: ${response.body}');


      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return BagPatientListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to get patient list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 $_tag getBagPatientList error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ─── Step 3: Accept bag (insert session event) ──────────────────────────────
  /// POST /InsertQRBagSession_Event
  /// Body: { "sessionid": sessionId, "processid": "8", "userid": userId }
  Future<BagSessionEventResponse> insertQRBagSessionEvent({
    required String sessionId,
    required String userId,
    String processId = '8',
  }) async {
    final body = {
      'sessionid': sessionId,
      'processid': processId,
      'userid': userId,
    };

    debugPrint('🚀 $_tag insertQRBagSessionEvent → ${AppUrls.insertQRBagSessionEvent}');
    debugPrint('📤 $_tag Body: $body');

    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.insertQRBagSessionEvent),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 $_tag Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ $_tag insertQRBagSessionEvent success');
        final jsonData = json.decode(response.body);
        return BagSessionEventResponse.fromJson(jsonData);
      } else {
        debugPrint('❌ $_tag HTTP ${response.statusCode}');
        throw Exception('Failed to accept bag: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 $_tag Network error: $e');
      throw Exception('Network error: $e');
    }
  }
}*/
