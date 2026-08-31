import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/network/app_urls.dart';

import '../../../network/api_client.dart';
import '../../../utils/helper_functions/helper_methods.dart';
import '../model/pending_test_model.dart';
import '../model/summary_model.dart';


import '../model/test_analysis_model.dart';
import '../model/test_type_model.dart';

class SummaryService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<SummaryModel?> fetchSummary({
    required String dateFrom,
    required String dateTo,
    required int distLgdCode,
    required int labCode,
    required int divId,
    required int facilityCode,
    required int designationId,
  }) async {
    kPrint('[SummaryService] Fetching summary from: ${AppUrls.summaryUrl}');

    // Prepare POST data
    final postData = {
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'DISTLGDCODE': distLgdCode.toString(),
      'LabCode': labCode.toString(),
      'DIVId': divId.toString(),
      'FacilityCode': facilityCode.toString(),
      'Desgid': designationId.toString()
    };

    kPrint('[SummaryService] POST data: $postData');

    try {
      final response = await apiClient.post(
        AppUrls.summaryUrl,
        data: postData,
      );

      kPrint(
          '[SummaryService] Summary response: ${response.body}');

      final jsonData = response.body;

      if (jsonData['status'] == 'Success' &&
          jsonData['output'] != null &&
          jsonData['output'].isNotEmpty) {
        return SummaryModel.fromJson(jsonData['output'][0]);
      } else {
        kPrint(
            '[SummaryService] Invalid response: status=${jsonData['status']}, output=${jsonData['output']}');
        return null;
      }
    } catch (e) {
      kPrint('[SummaryService] Error fetching summary: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchDetails({
    required String dateFrom,
    required String dateTo,
    required int distLgdCode,
    required int labCode,
    required int divId,
    required int facilityCode,
    required int designationId,
  }) async {
    try {
      final queryParameter = {
        /*  'dateFrom': dateFrom,
        'dateTo': dateTo,*/
        'DISTLGDCODE': distLgdCode.toString(),
        'LabCode': labCode.toString(),
        'DIVId': divId.toString(),
        'FacilityCode': facilityCode.toString(),
        'Desgid': designationId.toString(),
      };

      kPrint(
          '[SummaryService] Details query parameters: $queryParameter');
      kPrint(
          '[SummaryService] Details URL: ${AppUrls.summaryCountUrl}');

      final response = await apiClient.get(
        AppUrls.summaryCountUrl,
        queryParameters: queryParameter,
      );

      kPrint(
          '[SummaryService] Details response: ${response.body}');

      final jsonData = response.body;

      if (jsonData['status'] == 'Success') {
        return jsonData;
      } else {
        kPrint(
            '[SummaryService] Invalid response: status=${jsonData['status']}');
        return null;
      }
    } catch (e) {
      kPrint('[SummaryService] Error fetching details: $e');
      return null;
    }
  }

  // Add this method to your existing SummaryService class

  Future<List<TestAnalysisModel>?> fetchTestAnalysis({
    required String drill,
    required int divId,
    required int distLgdCode,
    required int labCode,
    required int facilityCode,
    int? fTypeId,
    required int testCategoryId,
    required int serviceCode,
    int? fTypeShort,
  }) async {
    kPrint(
        '[SummaryService] Fetching test analysis from: ${AppUrls.testAnalysisUrl}');

    // Manual query string construction to force empty values as "key="
    final queryParts = <String>[
      'DRILL=$drill',
      'DIVID=${divId.toString()}',
      'DISTLGDCODE=${distLgdCode.toString()}',
      'LabCode=${labCode.toString()}',
      'Facilitycode=${facilityCode.toString()}',
      // Force empty string → FTypeID= (exactly as your working example)
      'FTypeID=${(fTypeId != null && fTypeId != 0) ? fTypeId.toString() : ''}',
      'TestCategoryID=${testCategoryId.toString()}',
      'ServiceCode=${serviceCode.toString()}',
      'FTYPESHORT=${(fTypeShort != null && fTypeShort != 0) ? fTypeShort.toString() : ''}',
    ];

    final queryString = queryParts.join('&');

    final queryParameters = <String, dynamic>{
      'DRILL': drill,
      'DIVID': divId.toString(),
      'DISTLGDCODE': distLgdCode.toString(),
      'LabCode': labCode.toString(),
      'Facilitycode': facilityCode.toString(),
      'FTypeID': (fTypeId != null && fTypeId != 0) ? fTypeId.toString() : '',
      'TestCategoryID': testCategoryId.toString(),
      'ServiceCode': serviceCode.toString(),
      'FTYPESHORT':
      (fTypeShort != null && fTypeShort != 0) ? fTypeShort.toString() : '',
    };

    final uri = '${AppUrls.testAnalysisUrl}?$queryString';

    kPrint('[SummaryService] Test Analysis GET URL: $uri');

    try {
      // NOTE: Manual query string construction is retained here because the
      // existing API contract requires empty values to be sent as "key=".
      final response = await apiClient.get(
        AppUrls.testAnalysisUrl,
        queryParameters: queryParameters,
      );

      kPrint(
          '[SummaryService] Test Analysis response: ${response.body}');

      final jsonData = response.body;

      if (jsonData['status'] == 'Success' && jsonData['output'] != null) {
        final List<TestAnalysisModel> testAnalysisList = [];
        for (var item in jsonData['output']) {
          testAnalysisList.add(TestAnalysisModel.fromJson(item));
        }
        return testAnalysisList;
      } else {
        kPrint(
            '[SummaryService] Invalid response: status=${jsonData['status']}, message=${jsonData['message'] ?? 'No message'}');
        return null;
      }
    } catch (e) {
      kPrint('[SummaryService] Error fetching test analysis: $e');
      return null;
    }
  }

  // Add these methods to your existing SummaryService class

  Future<List<PendingPatientModel>?> fetchPendingPatients({
    required String fromDate,
    required String toDate,
    required int distLgdCode,
    required int divId,
    required int labCode,
    required int facilityCode,
  }) async {
    kPrint(
        '[SummaryService] Fetching pending patients from: ${AppUrls.pendingPatientUrl}');

    final queryParameters = {
      'Fromdate': fromDate,
      'Todate': toDate,
      'distlgdcode': distLgdCode.toString(),
      'DivId': divId.toString(),
      'Labcode': labCode.toString(),
      'FacilityCode': facilityCode.toString(),
    };

    kPrint(
        '[SummaryService] Pending Patients query parameters: $queryParameters');

    try {
      final response = await apiClient.get(
        AppUrls.pendingPatientUrl,
        queryParameters: queryParameters,
      );

      kPrint(
          '[SummaryService] Pending Patients response: ${response.body}');

      final jsonData = response.body;

      if (jsonData['status'] == 'Success' && jsonData['output'] != null) {
        final List<PendingPatientModel> pendingList = [];
        for (var item in jsonData['output']) {
          pendingList.add(PendingPatientModel.fromJson(item));
        }
        return pendingList;
      } else {
        kPrint(
            '[SummaryService] Invalid response: status=${jsonData['status']}');
        return null;
      }
    } catch (e) {
      kPrint('[SummaryService] Error fetching pending patients: $e');
      return null;
    }
  }

  Future<List<TestTypeModel>?> fetchTestTypeData({
    required String fromDate,
    required String toDate,
    required int labCode,
  }) async {
    kPrint(
        '[SummaryService] Fetching test type data from: ${AppUrls.testTypeUrl}');

    final queryParameters = {
      'FROMDATE': fromDate,
      'TODATE': toDate,
      'labcode': labCode.toString(),
    };

    kPrint(
        '[SummaryService] Test Type query parameters: $queryParameters');

    try {
      final response = await apiClient.get(
        AppUrls.testTypeUrl,
        queryParameters: queryParameters,
      );

      kPrint(
          '[SummaryService] Test Type response: ${response.body}');

      final jsonData = response.body;

      if (jsonData['status'] == 'Success' && jsonData['output'] != null) {
        final List<TestTypeModel> testTypeList = [];
        for (var item in jsonData['output']) {
          testTypeList.add(TestTypeModel.fromJson(item));
        }
        return testTypeList;
      } else {
        kPrint(
            '[SummaryService] Invalid response: status=${jsonData['status']}');
        return null;
      }
    } catch (e) {
      kPrint('[SummaryService] Error fetching test type data: $e');
      return null;
    }
  }
}