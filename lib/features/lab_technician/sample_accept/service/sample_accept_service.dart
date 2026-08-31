import 'dart:convert';

import 'package:lifenity_connect/features/lab_technician/sample_accept/model/resource_model.dart';

import 'package:lifenity_connect/features/lab_technician/sample_accept/model/sample_temparature_model.dart';
import 'package:get/get.dart';
import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../../phlebotomist/sample_pickup/model/work_item_model.dart';
import 'package:lifenity_connect/utils/helper_functions/debug_print.dart';

class SampleAcceptService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<List<ResourcesData>> getResourcesNamesAndVisitData(
      String labCode,
      String date,
      int designationId,
      ) async {
    try {
      final params = {
        'LabCode': labCode,
        'DesgID': designationId.toString(),
        'Fromdate': date,
      };

      kPrint('Request URL: ${AppUrls.getResourceVisitData}');
      kPrint('Request Body: $params');

      final response = await apiClient.post(
        AppUrls.getResourceVisitData,
        data: params,
      );

      kPrint('📥 Response: ${response.body}');

      final responseData = response.body;

      if (responseData['status'] == 'Success') {
        return (responseData['output'] as List)
            .map((item) => ResourcesData.fromJson(item))
            .toList();
      } else {
        kPrint(
          'No daily work found: ${responseData['message']}',
        );
        return [];
      }
    } catch (e) {
      kPrint('Error fetching daily work list: $e');
      rethrow;
    }
  }

  Future<List<WorkItem>> getListOfFacilitiesForSubmission(
      String runnerBoyUserId,
      String date,
      ) async {
    try {
      final params = {
        'RunnerBoyUserid': runnerBoyUserId,
        'date': date,
        'ForSubmitNOrAccept': '2',
      };

      kPrint('Request URL: ${AppUrls.getRunnerBoyWork}');
      kPrint('Request Body: $params');

      final response = await apiClient.post(
        AppUrls.getRunnerBoyWork,
        data: params,
      );

      kPrint('📥 Response: ${response.body}');

      final responseData = response.body;

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;

        return output
            .map((item) => WorkItem.fromJson(item))
            .toList();
      } else {
        kPrint(
          'No daily work found: ${responseData['message']}',
        );
        return [];
      }
    } catch (e) {
      kPrint('Error fetching daily work list: $e');
      rethrow;
    }
  }

  Future<List<SampleTemperatureData>> getTemperatureDropdown() async {
    try {
      kPrint(
        'Request URL: ${AppUrls.getSampleTemperature}',
      );

      final response = await apiClient.post(
        AppUrls.getSampleTemperature,
        data: {}
      );

      kPrint('📥 Response: ${response.body}');

      final responseData = response.body;

      if (responseData['status'] == 'Success') {
        return (responseData['output'] as List)
            .map((item) => SampleTemperatureData.fromJson(item))
            .toList();
      } else {
        kPrint(
          'No daily work found: ${responseData['message']}',
        );
        return [];
      }
    } catch (e) {
      kPrint('Error fetching daily work list: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitSamplesToLab({
    required List<Map<String, dynamic>> submissionData,
    required String remark,
    required int temperatureId,
  }) async {
    try {
      final jsonData = {
        'input': submissionData,
      };

      final jsonString = jsonEncode(jsonData);

      final body = {
        'jsonstring': jsonString,
        'Remark': remark,
        'Temprature': temperatureId.toString(),
      };

      kPrint(
        'Request URL: ${AppUrls.insertSampleSubmittedAcceptedStatus}',
      );
      kPrint('Request Body: $body');

      final response = await apiClient.post(
        AppUrls.insertSampleSubmittedAcceptedStatus,
        data: body,
      );

      kPrint('📥 Response: ${response.body}');

      final responseData = response.body;

      return {
        'status': responseData['status']?.toString() ?? 'fail',
        'message': responseData['message']?.toString() ?? '',
      };
    } catch (e) {
      kPrint('Error submitting samples: $e');
      rethrow;
    }
  }
}/*class SampleAcceptService {

  Future<List<ResourcesData>> getResourcesNamesAndVisitData(String labCode,
      String date, int designationId) async {
    try {
      final params = {
        'LabCode': labCode,
        'DesgID': designationId.toString(),
        'Fromdate': date,
      };

      final uri = Uri.parse(AppUrls.getResourceVisitData)
          .replace(queryParameters: params);
      CustomDebugFunction.log('Request URL: $uri');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      HelperMethods.printLongString(response.body);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch daily work list');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'Success') {
        return (responseData['output'] as List)
            .map((item) => ResourcesData.fromJson(item))
            .toList();
      } else {
        CustomDebugFunction.log('No daily work found: ${responseData['message']}');
        return [];
      }
    } catch (e) {
      CustomDebugFunction.log('Error fetching daily work list: $e');
      rethrow;
    }
  }

  Future<List<WorkItem>> getListOfFacilitiesForSubmission(
      String runnerBoyUserId, String date, ) async {
    try {
      final params = {
        'RunnerBoyUserid': runnerBoyUserId,
        'date': date,
        'ForSubmitNOrAccept': '2',
      };

      final uri = Uri.parse(AppUrls.getRunnerBoyWork).replace(queryParameters: params);
      CustomDebugFunction.log('Request URL: $uri');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      HelperMethods.printLongString(response.body);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch daily work list');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;
        return output.map((item) => WorkItem.fromJson(item)).toList();
      } else {
        CustomDebugFunction.log('No daily work found: ${responseData['message']}');
        return [];
      }
    } catch (e) {
      CustomDebugFunction.log('Error fetching daily work list: $e');
      rethrow;
    }
  }

  Future<List<SampleTemperatureData>> getTemperatureDropdown() async {
    try {


      final uri = Uri.parse(AppUrls.getSampleTemperature);


      final response = await http.get(uri, headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      HelperMethods.printLongString(response.body);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch daily work list');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'Success') {
        return (responseData['output'] as List)
            .map((item) => SampleTemperatureData.fromJson(item))
            .toList();
      } else {
        CustomDebugFunction.log('No daily work found: ${responseData['message']}');
        return [];
      }
    } catch (e) {
      CustomDebugFunction.log('Error fetching daily work list: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitSamplesToLab({
    required List<Map<String, dynamic>> submissionData,
    required String remark,
    required int temperatureId,
  }) async {
    try {
      final jsonData = {'input': submissionData};
      final jsonString = jsonEncode(jsonData);

      final uri = Uri.parse(
        AppUrls.insertSampleSubmittedAcceptedStatus,
      );
      CustomDebugFunction.log(uri);
      CustomDebugFunction.log(jsonString);
      CustomDebugFunction.log(remark);
      CustomDebugFunction.log(temperatureId);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},

        body: {
          'jsonstring': jsonString,
          'Remark': remark,
          'Temprature': temperatureId.toString(),
        },
      );


      HelperMethods.printLongString(response.body);

      if (response.statusCode != 200) {
        throw Exception('Failed to submit samples: HTTP ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body);

      return {
        'status': responseData['status']?.toString() ?? 'fail',
        'message': responseData['message']?.toString() ?? '',
      };
    } catch (e) {
      CustomDebugFunction.log('Error submitting samples: $e');
      rethrow;
    }
  }
}*/
