
import 'package:get/get.dart';
import 'package:lifenity_connect/features/team_lead/sample_remark/model/facilityRemarkModel.dart';
import 'package:lifenity_connect/features/team_lead/sample_remark/model/sample_remark_model.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';




import '../../../../utils/helper_functions/helper_methods.dart';

class SampleRemarkService {
  final APIClient apiClient = Get.find<APIClient>();

  // Fetch the remark list
  Future<List<SampleRemarkModel>> fetchSampleRemarkList() async {
    try {
      final response = await apiClient.post(
        AppUrls.sampleRemarkList,
        data : {}
      );

      kPrint('📬 fetchSampleRemarkList response: ${response.body}');

      final responseData = response.body;

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;
        return output.map((item) => SampleRemarkModel.fromJson(item)).toList();
      } else {
        kPrint('No remarks found: ${responseData['message']}');
        return [];
      }
    } catch (e) {
      kPrint('❌ Error fetching sample remarks: $e');
      throw Exception('Failed to fetch sample remarks: $e');
    }
  }

  // Fetch data for sample remark - returns list if no samples recorded (count = 0)
  Future<List<FacilityRemarkModel>> fetchDataForSampleRemark(
      String labCode, String facilityCode, String selectedDate) async {
    try {
      final params = {
        'LabCode': labCode,
        'Date': selectedDate,
        'FacilityCode': facilityCode,
      };

      kPrint(
        '📬 fetchDataForSampleRemark URL: ${AppUrls.getCountsForDc}',
      );
      kPrint('📬 fetchDataForSampleRemark params: $params');

      final response = await apiClient.post(
        AppUrls.getCountsForDc,
        data: params,
      );

      kPrint('📬 fetchDataForSampleRemark response: ${response.body}');

      final responseData = response.body;

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;
        return output.map((item) => FacilityRemarkModel.fromJson(item)).toList();
      } else {
        // Return empty list if no data found (means samples were collected)
        return [];
      }
    } catch (e) {
      kPrint('❌ Error fetching sample remark data: $e');
      throw Exception('Failed to fetch sample remark data: $e');
    }
  }

  // Add zero remark - API call to insert patient count sample
  Future<bool> addZeroRemark({
    required String centerId,
    required String count,
    required String date,
    required String userId,
    required String createdBy,
    required String desgId,
    required String remark,
    required String remarkId,
  }) async {
    try {
      final params = {
        'CenterID': centerId,
        'Count': count,
        'Date': date,
        'UserId': userId,
        'CreatedBy': createdBy,
        'DesgId': desgId,
        'Remark': remark,
        'REMARKID': remarkId,
      };

      kPrint('📬 addZeroRemark URL: ${AppUrls.insertSampleRemark}');
      kPrint('📬 addZeroRemark params: $params');

      final response = await apiClient.post(
        AppUrls.insertSampleRemark,
        data: params,
      );

      kPrint('📬 addZeroRemark response: ${response.body}');

      final responseData = response.body;

      // Check if the response indicates success
      if (responseData['status'] == 'Success' ||
          responseData['message']
              ?.toString()
              .toLowerCase()
              .contains('success') ==
              true) {
        return true;
      } else {
        kPrint('❌ API returned error: ${responseData['message']}');
        return false;
      }
    } catch (e) {
      kPrint('❌ Error submitting zero remark: $e');
      throw Exception('Failed to submit zero remark: $e');
    }
  }
}
/*class SampleRemarkService {
  // Fetch the remark list
  Future<List<SampleRemarkModel>> fetchSampleRemarkList() async {
    try {
      final uri = Uri.parse(AppUrls.sampleRemarkList);

      final response = await http.get(uri);

      debugPrint('📬 fetchSampleRemarkList response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch sample remarks');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;
        return output.map((item) => SampleRemarkModel.fromJson(item)).toList();
      } else {
        print('No remarks found: ${responseData['message']}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching sample remarks: $e');
      throw Exception('Failed to fetch sample remarks: $e');
    }
  }

  // Fetch data for sample remark - returns list if no samples recorded (count = 0)
  Future<List<FacilityRemarkModel>> fetchDataForSampleRemark(
      String labCode, String facilityCode, String selectedDate) async {
    try {
      final uri = Uri.parse(AppUrls.getCountsForDc).replace(queryParameters: {
        'LabCode': labCode,
        'Date': selectedDate,
        'FacilityCode': facilityCode,
      });

      debugPrint('📬 fetchDataForSampleRemark URL: $uri');

      final response = await http.get(uri);

      debugPrint('📬 fetchDataForSampleRemark response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch sample remark data');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;
        return output.map((item) => FacilityRemarkModel.fromJson(item)).toList();
      } else {
        // Return empty list if no data found (means samples were collected)
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching sample remark data: $e');
      throw Exception('Failed to fetch sample remark data: $e');
    }
  }

  // Add zero remark - API call to insert patient count sample
  Future<bool> addZeroRemark({
    required String centerId,
    required String count,
    required String date,
    required String userId,
    required String createdBy,
    required String desgId,
    required String remark,
    required String remarkId,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.insertSampleRemark).replace(queryParameters: {
        'CenterID': centerId,
        'Count': count,
        'Date': date,
        'UserId': userId,
        'CreatedBy': createdBy,
        'DesgId': desgId,
        'Remark': remark,
        'REMARKID': remarkId,
      });

      debugPrint('📬 addZeroRemark URL: $uri');

      final response = await http.get(uri);

      debugPrint('📬 addZeroRemark response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to submit zero remark');
      }

      final responseData = jsonDecode(response.body);

      // Check if the response indicates success
      if (responseData['status'] == 'Success' ||
          responseData['message']?.toString().toLowerCase().contains('success') == true) {
        return true;
      } else {
        debugPrint('❌ API returned error: ${responseData['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error submitting zero remark: $e');
      throw Exception('Failed to submit zero remark: $e');
    }
  }
}*/


