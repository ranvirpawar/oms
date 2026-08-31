import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:lifenity_connect/network/app_urls.dart';

import '../../../network/api_client.dart';
import '../../../utils/helper_functions/helper_methods.dart';
import '../model/facility_type_model.dart';

class FacilityTypeService {

  static final String facilityTypeApiUrl = AppUrls.facilityTypeSummary;

  final APIClient apiClient = Get.find<APIClient>();

  Future<List<FacilityTypeModel>?> fetchFacilityTypes({
    required String fromDate,
    required String toDate,
    required int ftype,
    required int desgId,
  }) async {
    kPrint('[FacilityTypeService] Fetching facility types');

    final postData = {
      'type': '1',
      'fromdate': fromDate,
      'todate': toDate,
      'ftype': ftype.toString(),
      'desgid': desgId.toString(),
    };

    kPrint('[FacilityTypeService] POST data: $postData');
    kPrint('[FacilityTypeService] API URL: $facilityTypeApiUrl');

    try {
      final response = await apiClient.post(
        facilityTypeApiUrl,
        data: postData,
      );

      kPrint(
          '[FacilityTypeService] Response body: ${response.body}');

      final jsonData = response.body;

      if (jsonData['status'] == 'Success' && jsonData['output'] != null) {
        final List<FacilityTypeModel> facilityTypes = [];
        for (var item in jsonData['output']) {
          facilityTypes.add(FacilityTypeModel.fromJson(item));
        }
        return facilityTypes;
      } else {
        kPrint(
            '[FacilityTypeService] Invalid response: status=${jsonData['status']}');
        return null;
      }
    } catch (e) {
      kPrint('[FacilityTypeService] Error fetching facility types: $e');
      return null;
    }
  }

  Future<List<FacilityModel>?> fetchFacilities({
    required String fromDate,
    required String toDate,
    required int ftypeId,
    required int desgId,
  }) async {
    kPrint(
        '[FacilityTypeService] Fetching facilities for type: $ftypeId');

    final postData = {
      'type': '0',
      'fromdate': fromDate,
      'todate': toDate,
      'ftype': ftypeId.toString(),
      'desgid': desgId.toString(),
    };

    kPrint('[FacilityTypeService] POST data: $postData');

    try {
      final response = await apiClient.post(
        facilityTypeApiUrl,
        data: postData,
      );

      kPrint(
          '[FacilityTypeService] Response body: ${response.body}');

      final jsonData = response.body;

      if (jsonData['status'] == 'Success' && jsonData['output'] != null) {
        final List<FacilityModel> facilities = [];
        for (var item in jsonData['output']) {
          facilities.add(FacilityModel.fromJson(item));
        }
        return facilities;
      } else {
        kPrint(
            '[FacilityTypeService] Invalid response: status=${jsonData['status']}');
        return null;
      }
    } catch (e) {
      kPrint('[FacilityTypeService] Error fetching facilities: $e');
      return null;
    }
  }
}
