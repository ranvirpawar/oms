import 'dart:convert';

import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import '../../../network/api_client.dart';
import '../../../network/app_urls.dart';
import '../../../utils/helper_functions/helper_methods.dart';
import '../../phlebotomist/patient_queue/service/patient_queue_service.dart';
import '../model/dashboard_summary_model.dart';

class DashboardStatsService {
  final APIClient _apiClient = Get.find<APIClient>();

  Future<PhleboDashboardSummary> fetchDashboardCount({required String userId}) async {
    try {
      final response = await _apiClient.get('${AppUrls.dashboardCount}?userId=$userId');

      final Map<String, dynamic> body = response.data is String ? jsonDecode(response.data as String) : response.data as Map<String, dynamic>;

      return PhleboDashboardSummary.fromJson(body);
    } catch (e) {
      kPrint('❌ fetchDashboardCount: $e');
      rethrow;
    }
  }
}
