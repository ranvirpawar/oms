import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/network/app_urls.dart';

import '../../../../network/api_client.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/zero_sample_data_model.dart';


class ZeroSampleService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<ZeroSampleResponse> getZeroSampleData({
    required String monthId,
    required String year,
    required int type,
    int distLgdCode = 0,
    int labCode = 0,
    required String divId,
    String visitDate = '',
    int remarkId = 0,
    required String userId,
  }) async {
    try {
      final queryParams = {
        'MonthId': monthId,
        'Year': year,
        'Type': type,
        'DISTLGDCODE': distLgdCode,
        'LabCode': labCode,
        'DIVID': divId,
        'VisitDate': visitDate,
        'RemarkID': remarkId,
        'Userid': userId,
      };

      kPrint('Request URL: ${AppUrls.zeroSampleCalendar}');
      kPrint('Request params: $queryParams');

      final response = await apiClient.post(
        AppUrls.zeroSampleCalendar,
        data: queryParams,
      );

      final jsonData = response.body;
      kPrint(jsonData.toString());

      return ZeroSampleResponse.fromJson(jsonData);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}