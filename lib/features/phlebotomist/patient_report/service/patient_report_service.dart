
import 'package:flutter/cupertino.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_report/model/consent_status_model.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';


import '../model/patiet_report_data.dart';
import '../model/test_status_model.dart';

class PatientReportService {
  final APIClient apiClient = Get.find<APIClient>();

  // ─────────────────────────────────────────────
  // GET APIs (query parameters)
  // ─────────────────────────────────────────────

  Future<List<PatientReportData>> getPatientReportsList({
    required String userId,
    required String fromDate,
    required String toDate,
    required String facilityCode,
    required String mobileNumber,
  }) async {
    try {
      final response = await apiClient.post(
        AppUrls.reportBaseUrl,
        data: {
          'FacilityCode': facilityCode,
          'dateFrom': fromDate,
          'dateTo': toDate,
          'userid': userId,
          'mobile_no': mobileNumber,
        },
      );

      final data = response.body; // or response.data depending on your client

      if (data['status'] == 'Success') {
        final output = data['output'] as List;
        return output.map((item) => PatientReportData.fromJson(item)).toList();
      }

      debugPrint('No reports found: ${data['message']}');
      return [];
    } catch (e) {
      debugPrint('Error fetching patient reports: $e');
      rethrow;
    }
  }

  Future<List<ConsentStatusModel>> getConsentStatus(String mobileNumber) async {
    try {
      final response = await apiClient.post(
        AppUrls.consentStatus,
        data: {
          'MobileNo': mobileNumber,
        },
      );

      final data = response.body;

      if (data['status'] == 'Success') {
        final output = data['output'] as List;
        return output
            .map((item) => ConsentStatusModel.fromJson(item))
            .toList();
      }

      debugPrint('No consent data: ${data['message']}');
      return [];
    } catch (e) {
      debugPrint('Error fetching consent status: $e');
      rethrow;
    }
  }

  Future<List<TestStatusModel>> getPatientTestList(String orderId) async {
    try {
      final response = await apiClient.post(
        AppUrls.getPatientTestListWithStatus,
        data: {
          'orderid': orderId,
        },
      );

      final data = response.body;

      if (data['status'] == 'Success') {
        final output = data['output'] as List;
        return output.map((e) => TestStatusModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching test list: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // POST APIs – still form-urlencoded (legacy / ASMX style)
  // Keep this format because backend expects it + returns XML
  // ─────────────────────────────────────────────

  Future<bool> sendReportToWhatsApp({
    required String mobile,
    required String barcode,
  }) async {
    try {
      final response = await apiClient.post(
        AppUrls.sendReportToWhatsApp,
        data: {
          'orderid': barcode,
          'mobileNo': mobile,
        },
      );

      // Response is XML, so we only check status code
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending report to WhatsApp: $e');
      return false;
    }
  }

  Future<bool> sendConsentToWhatsApp(String mobile) async {
    try {
      final response = await apiClient.post(
        AppUrls.SendConsentMessage_Consent,
        data: {
          'mobileNo': mobile,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending consent to WhatsApp: $e');
      return false;
    }
  }
}
