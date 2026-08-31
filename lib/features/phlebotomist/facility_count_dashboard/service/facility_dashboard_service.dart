import 'dart:convert';




import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/facility_data_model.dart';


import 'package:lifenity_connect/utils/helper_functions/debug_print.dart';

class FacilityDashboardService {
  final APIClient _apiClient = Get.find<APIClient>();

  Future<List<FacilityData>> getFacilityRegistrationData(
      Map<String, dynamic> input,
      ) async {
    try {
      final formData = {
        'orderdate': input['orderdate'].toString(),
        'labcode': input['labcode'].toString(),
        'Userid': input['Userid'].toString(),
      };

      kPrint('📡 Submitting Facility Data Request:\n$formData');
      kPrint('➡️ URL: ${AppUrls.getFacilityData}');
      kPrint('➡️ Body: $formData');

      final result = await _apiClient.post(
        AppUrls.getFacilityData,
        data: formData,

      );

      kPrint('📬 Facility Data Response');
      kPrint('⬅️ Status Code: ${result.statusCode}');
      kPrint('⬅️ Body: ${result.data}');

      final resData = result.body;

      if (resData['status'] == 'Success') {
        final List<dynamic> facilityList = resData['output'] ?? [];
        return facilityList
            .map((json) => FacilityData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      kPrint('❌ Facility Data Fetch Error: $e');
      rethrow;
    }
  }
}
