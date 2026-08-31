import 'package:lifenity_connect/features/phlebotomist/sample_recollection/model/rejected_tests_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/model/test_recollection_model.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import 'dart:convert';


import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/rejection_reason_model.dart';
import 'package:get/get.dart';
class SampleRecollectionService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<List<RecollectionTestListUpdated>> fetchRecollectionDataUpdated({
    required String formDate,
    required String toDate,
    required String facilityId,
    required String type,
  }) async {
    try {
      final body = {
        'FROMDATE': formDate,
        'TODATE': toDate,
        'FacilityCode': facilityId,
        'IsRecollection': type,
      };

      kPrint('📬 recollection request body: $body');
      kPrint(AppUrls.sampleRecollectionListUpdated);

      final response = await apiClient.post(
        AppUrls.sampleRecollectionListUpdated,
        data: body,
      );

      final responseData = response.body;

      kPrint('📬 recollection response: $responseData');

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;

        return output
            .map((item) => RecollectionTestListUpdated.fromJson(item))
            .toList();
      } else {
        kPrint(': ${responseData['message']}');
        return [];
      }
    } catch (e) {
      kPrint('❌ Error fetching recollection data : $e');
      throw Exception('Error fetching recollection data: $e');
    }
  }

  Future<List<RejectedTests>> getRejectedTestDetails({
    required String visitCode,
  }) async {
    try {
      final response = await apiClient.post(
        AppUrls.rejectedTestDetails,
        data: {
          'Visitcode': visitCode,
        },
      );

      final responseData = response.body;

      kPrint('📬 rejected test data : $responseData');

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;

        return output.map((item) => RejectedTests.fromJson(item)).toList();
      } else {
        kPrint('No daily work found: ${responseData['message']}');
        return [];
      }
    } catch (e) {
      kPrint('❌ Error fetching rejected test data : $e');
      throw Exception('Error fetching rejected test data: $e');
    }
  }

  // Single get method to fetch list of DenyRemarkModel.
  Future<List<DenyRemarkModel>> fetchRejectionRemarks() async {
    try {
      final response = await apiClient.post(
        AppUrls.rejectionRemark,
        data: {}
      );

      final responseData = response.body;

      kPrint('📬 fetch response: $responseData');

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;

        return output.map((item) => DenyRemarkModel.fromJson(item)).toList();
      } else {
        kPrint('No remarks found: ${responseData['message']}');
        return [];
      }
    } catch (e) {
      kPrint('❌ Error fetching rejection remarks : $e');
      throw Exception('Failed to fetch rejection remarks: $e');
    }
  }

  Future<bool> denyRecollection({
    required int visitCode,
    required List<RejectedTests> selectedTests,
    required String denyRemark,
    required String userId,
  }) async {
    try {
      // Construct the MobileEntrySampleCollection JSON array.
      final mobileEntrySampleCollection = selectedTests.map((test) {
        return {
          'Visitcode': visitCode,
          'OrderID': test.orderId,
          'NewOrderID': '',
          'ServiceCode': test.serviceCode,
          'IsRecollection': 3,
          'DenyRemark': denyRemark,
        };
      }).toList();

      final body = {
        'MobileEntrySampleCollection':
        jsonEncode(mobileEntrySampleCollection),
        'IsRecollectionBy': userId.toString(),
      };

      kPrint('📬 deny recollection body: $body');

      final response = await apiClient.post(
        AppUrls.insertRecollectionUpdate,
        data: body,
      );

      final responseData = response.body;

      kPrint('📬 deny recollection response: $responseData');

      if (responseData['status'] == 'Success') {
        return true;
      } else {
        kPrint(
          'Failed to deny recollection: ${responseData['message']}',
        );
        return false;
      }
    } catch (e) {
      kPrint('❌ Error denying recollection : $e');
      throw Exception('Failed to deny recollection: $e');
    }
  }

  Future<bool> acceptRecollection({
    required int visitCode,
    required List<RejectedTests> selectedTests,
    required String barcode,
    required String userId,
  }) async {
    try {
      // Construct the MobileEntrySampleCollection JSON array.
      final mobileEntrySampleCollection = selectedTests.map((test) {
        return {
          'Visitcode': visitCode,
          'OrderID': test.orderId,
          'NewOrderID': barcode,
          'ServiceCode': test.serviceCode,
          'IsRecollection': 1,
          'DenyRemark': '',
        };
      }).toList();

      kPrint(
        '📬 Accept recollection payload: $mobileEntrySampleCollection',
      );

      final body = {
        'MobileEntrySampleCollection':
        jsonEncode(mobileEntrySampleCollection),
        'IsRecollectionBy': userId.toString(),
      };

      kPrint('📬 Accept recollection body: $body');

      final response = await apiClient.post(
        AppUrls.insertRecollectionUpdate,
        data: body,
      );

      final responseData = response.body;

      kPrint('📬 Accept recollection response: $responseData');

      if (responseData['status'] == 'Success') {
        return true;
      } else {
        kPrint(
          'Failed to accept recollection: ${responseData['message']}',
        );
        return false;
      }
    } catch (e) {
      kPrint('❌ Error in accept recollection : $e');
      throw Exception('Failed to accept recollection: $e');
    }
  }
}
