import 'package:flutter/cupertino.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../model/phlebo_sample_pickup.dart';
import '../model/work_item_model.dart'; // for debugPrint
class SamplePickupService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<List<WorkItem>> getDailyWorkList(
      String runnerBoyUserId,
      String date,
      int forSubmitOrNot,
      ) async {
    try {
      final response = await apiClient.post(
        AppUrls.getRunnerBoyWork,
        queryParameters: {
          'RunnerBoyUserid': runnerBoyUserId,
          'date': date,
          'ForSubmitNOrAccept': forSubmitOrNot.toString(),
        },
      );

      final data = response.body; // adjust to response.data if needed

      if (data['status'] == 'Success') {
        final output = data['output'] as List;
        return output.map((item) => WorkItem.fromJson(item)).toList();
      }

      debugPrint('No daily work found: ${data['message']}');
      return [];
    } catch (e) {
      debugPrint('Error fetching daily work list: $e');
      rethrow;
    }
  }

  Future<List<PhleboSamplePickup>> fetchFacilityWiseDataForPickup(
      Map<String, dynamic> reqbody,
      ) async {
    try {
      final queryParams = reqbody.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
      );

      final response = await apiClient.post(
        AppUrls.getFacilityWiseDataForPickup,
        data: queryParams,
      );

      final data = response.body;

      if (data['status'] == 'Success') {
        final facilityResponse = FacilityResponse.fromJson(data);
        return facilityResponse.output;
      }

      debugPrint('No data found: ${data['message']}');
      return [];
    } catch (e, stack) {
      debugPrint('Error fetching facility wise data: $e');
      debugPrint('Stacktrace: $stack');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitSamplesToLab(
      List<Map<String, dynamic>> submissionData,
      ) async {
    try {
      final jsonData = {
        'input': submissionData,
      };

      debugPrint('📤 Submit to Lab Request: ${jsonEncode(jsonData)}');

      final response = await apiClient.post(
        AppUrls.insertSampleSubmittedAcceptedStatus,
        data: {
          'jsonstring': jsonEncode(jsonData),
          'Remark': '',
          'Temprature': '1',
        },
      );

      debugPrint('📬 Submit to Lab Response: ${response.body}');

      return response.body;
    } catch (e) {
      debugPrint('❌ Error submitting to lab: $e');
      throw Exception('Failed to submit samples to lab: $e');
    }
  }
}

/*
class SamplePickupService {
  Future<List<WorkItem>> getDailyWorkList(
      String runnerBoyUserId, String date, int forSubmitOrNot) async {
    try {
      final params = {
        'RunnerBoyUserid': runnerBoyUserId,
        'date': date,
        'ForSubmitNOrAccept': forSubmitOrNot.toString(),
      };
      print(params.toString());

      final uri = Uri.parse(AppUrls.getRunnerBoyWork).replace(queryParameters: params);

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch daily work list');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;
        return output.map((item) => WorkItem.fromJson(item)).toList();
      } else {
        debugPrint('⚠️ No daily work found: ${responseData['message']}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching daily work list: $e');
      rethrow;
    }
  }

  Future<List<PhleboSamplePickup>> fetchFacilityWiseDataForPickup(
      Map<String, dynamic> reqbody) async {
    try {
      // ✅ Convert all values to String to avoid "int is not a subtype of Iterable"
      final params = reqbody.map((key, value) => MapEntry(key, value?.toString() ?? ""));

      final queryString = params.entries
          .map((e) => "${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}")
          .join("&");
final url = AppUrls.getFacilityWiseDataForPickup;
      final uri = Uri.parse("$url?$queryString");
      debugPrint("🌐 Request URL: $uri");

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      debugPrint("📥 Status Code: ${response.statusCode}");
      debugPrint("📥 Raw Response Body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch daily work list');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'Success') {
        final facilityResponse = FacilityResponse.fromJson(responseData);
        return facilityResponse.output;
      } else {
        debugPrint('⚠️ No daily work found: ${responseData['message']}');
        return [];
      }
    } catch (e, stack) {
      debugPrint('❌ Error fetching daily work list: $e');
      debugPrint('📄 Stacktrace: $stack');
      rethrow;
    }
  }

}*/
