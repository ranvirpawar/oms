// services/visit_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/model/facility_center_name_model.dart';
import 'package:lifenity_connect/network/app_urls.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';

import '../../../../network/api_client.dart';
import '../model/facility_center_type_model.dart';
import '../model/visit_model.dart';
import '../model/visit_request_model.dart';
import '../model/visit_response_model.dart';

class VisitService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<List<FacilityCenterName>> getFacilityList(
      String distLgdCode, int centerTypeId) async {
    try {
      final url = AppUrls.getFacilityCenterNames;
      final queryParams = {
        'DISTLGDCODE': distLgdCode,
        'CenterTypeID': centerTypeId,
      };

      kPrint('Fetching facilities with URL: $url and params: $queryParams');

      final response = await apiClient.post(
        url,
        data: queryParams,
      );

      kPrint('Response data: ${response.body}');

      // Add null safety check
      if (response.body == null) {
        throw Exception('No data received from server');
      }

      final data = response.body;

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList
            .map((json) => FacilityCenterName.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load facilities: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      kPrint('Error in getFacilityList: $e'); // Debug logging
      rethrow;
    }
  }

  // Get facility type list
  Future<List<FacilityCenterType>> getFacilityTypeList(String userId) async {
    try {
      final url = AppUrls.getFacilityCenterTypes;
      final queryParams = {
        'UserID': userId,
      };

      final response = await apiClient.post(
        url,
        data: queryParams,
      );

      kPrint('Response data: ${response.body}');

      // Add null safety check
      if (response.body == null) {
        throw Exception('No data received from server');
      }

      // Decode the JSON string to a Map
      final Map<String, dynamic> data = response.body;

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList
            .map((json) => FacilityCenterType.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load facility types: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      kPrint('Error in getFacilityTypeList: $e'); // Debug logging
      rethrow;
    }
  }

  Future<VisitResponseModel> submitVisit(VisitRequestModel request) async {
    try {
      final url = AppUrls.insertFacilityVisit;
      kPrint('Submitting visit to URL: $url with data: ${request.toJson()}');

      final response = await apiClient.post(
        url,
        data: request.toJson(),
      );

      kPrint('Response data: ${response.body}');
      final data = response.body;

      return VisitResponseModel.fromJson(data);
    } catch (e, stacktrace) {
      kPrint('Error in submitVisit: $e');
      debugPrintStack(stackTrace: stacktrace);
      throw Exception(
        'Failed to submit visit: $e',
      );
    }
  }

  Future<Map<String, dynamic>> uploadPhoto({
    required String userId,
    required int surveyId,
    required File imageFile,
  }) async {
    try {
      final url = AppUrls.uploadVisitPhoto;

      final FormData formData = FormData.fromMap({
        'type': 'IMG',
        'USERID': userId,
        'SurveyID': surveyId,
        'fileUpload': await MultipartFile.fromFile(
          imageFile.path,
          filename:
          'survey_${surveyId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await apiClient.post(
        url,
        data: formData,
        isFormData: true,
      );

      kPrint('Response data: ${response.body}');

      // Ensure response is always a Map
      return response.body;
    } catch (e) {
      kPrint('Error in uploadPhoto: $e');

      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<VisitResponse> getFacilitySurvey({
    required DateTime fromDate,
    required DateTime toDate,
    required String userId,
  }) async {
    try {
      final String formattedFromDate =
      DateFormat('yyyy-MM-dd').format(fromDate);
      final String formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);

      final queryParams = {
        'FromDate': formattedFromDate,
        'Todate': formattedToDate,
        'USERID': userId,
      };

      kPrint(
        'URL: ${AppUrls.facilitySurvey}',
      );
      kPrint('Params: $queryParams');

      final response = await apiClient.post(
        AppUrls.facilitySurvey,
        data: queryParams,
      );

      final Map<String, dynamic> jsonData = response.body;
      kPrint(jsonData.toString());

      return VisitResponse.fromJson(jsonData);
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}
/*class VisitService {
  final Dio _dio = Dio();

  Future<List<FacilityCenterName>> getFacilityList(
      String distLgdCode, int centerTypeId) async {
    try {
      final url = AppUrls.getFacilityCenterNames;
      final queryParams = {
        'DISTLGDCODE': distLgdCode,
        'CenterTypeID': centerTypeId,
      };

      kPrint('Fetching facilities with URL: $url and params: $queryParams');
      final response = await _dio.get(url, queryParameters: queryParams);
      kPrint('Response data: ${response.data}');

      // Add null safety check
      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final data = jsonDecode(response.data);

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList
            .map((json) => FacilityCenterName.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load facilities: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      kPrint('Error in getFacilityList: $e'); // Debug logging
      rethrow;
    }
  }

  // Get facility type list
  Future<List<FacilityCenterType>> getFacilityTypeList(String userId) async {
    try {
      final url = AppUrls.getFacilityCenterTypes;
      final queryParams = {
        'UserID': userId,
      };

      final response = await _dio.get(url, queryParameters: queryParams);
      kPrint('Response data: ${response.data}');

      // Add null safety check
      if (response.data == null) {
        throw Exception('No data received from server');
      }

      // Decode the JSON string to a Map
      final Map<String, dynamic> data = json.decode(response.data);

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];
        return outputList
            .map((json) => FacilityCenterType.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load facility types: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      kPrint('Error in getFacilityTypeList: $e'); // Debug logging
      rethrow;
    }
  }

  Future<VisitResponseModel> submitVisit(VisitRequestModel request) async {
    try {
      final url = AppUrls.insertFacilityVisit;
      kPrint('Submitting visit to URL: $url with data: ${request.toJson()}');

      final response = await _dio.post(
        url,
        data: request.toJson(),
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      kPrint('Response data: ${response.data}');
      final data = jsonDecode(response.data);
      return VisitResponseModel.fromJson(data);
    } catch (e, stacktrace) {
      kPrint('Error in submitVisit: $e');
      debugPrintStack(stackTrace: stacktrace);
      throw Exception(
        'Failed to submit visit: $e',
      );
    }
  }

  Future<Map<String, dynamic>> uploadPhoto({
    required String userId,
    required int surveyId,
    required File imageFile,
  }) async {
    try {
      final url = AppUrls.uploadVisitPhoto;

      final FormData formData = FormData.fromMap({
        'type': 'IMG',
        'USERID': userId,
        'SurveyID': surveyId,
        'fileUpload': await MultipartFile.fromFile(
          imageFile.path,
          filename:
              'survey_${surveyId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      kPrint('Response data: ${response.data}');

      // Ensure response is always a Map
      if (response.data is String) {
        return jsonDecode(response.data);
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      kPrint('Error in uploadPhoto: $e');

      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<VisitResponse> getFacilitySurvey({
    required DateTime fromDate,
    required DateTime toDate,
    required String userId,
  }) async {
    try {
      final String formattedFromDate =
          DateFormat('yyyy-MM-dd').format(fromDate);
      final String formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);

      final String url =
          '${AppUrls.facilitySurvey}?FromDate=$formattedFromDate&Todate=$formattedToDate&USERID=$userId';

      HelperMethods.printLongString('URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        HelperMethods.printLongString(jsonData.toString());
        return VisitResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load facility survey data');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}*/
