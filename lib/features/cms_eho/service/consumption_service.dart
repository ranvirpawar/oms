


import 'package:get/get.dart';

import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';

import '../../../network/api_client.dart';
import '../../../network/app_urls.dart';
import '../model/consumption_model.dart';
import '../model/facility_detail_model.dart';


class ConsumptionService {
  final APIClient apiClient = Get.find<APIClient>();

  // ── TYPE 1 — Dashboard summary (existing, unchanged) ─────────────────────
  Future<List<ConsumptionModel>> fetchConsumption({
    int type = 1,
    required int desgId,
    int fTypeId = 0,
    int year = 1,
  }) async {
    final body = {
      'type': type.toString(),
      'desgid': desgId.toString(),
      'ftype': fTypeId.toString(),
      'Year': year.toString(),
      'ward': ''
    };

    kPrint('[ConsumptionService] POST ${AppUrls.consumptionDashboard}  body=$body');

    final response = await apiClient.post(
      AppUrls.consumptionDashboard,
      data: body,
    );

    kPrint('[ConsumptionService] Status: ${response.statusCode}');
    kPrint('[ConsumptionService] Body: ${response.body}');

    final jsonData = response.body;

    if (jsonData['status'] != 'Success') {
      throw Exception(
        'API error: ${jsonData['message'] ?? 'Unknown error'}',
      );
    }

    return (jsonData['output'] as List<dynamic>)
        .map((item) => ConsumptionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── TYPE 2 — Facility category detail ────────────────────────────────────
  /// Pass [fTypeId] from the tapped card, [yearId] from the year filter.
  Future<List<FacilityDetailModel>> fetchDetail({
    required int desgId,
    required int fTypeId,
    int yearId = 1,
  }) async {
    final body = {
      'type': '2',
      'desgid': desgId.toString(),
      'ftype': fTypeId.toString(),
      'Year': yearId.toString(),
      'ward': ''
    };

    kPrint(
      '[ConsumptionService] fetchDetail POST ${AppUrls.consumptionDashboard}  body=$body',
    );

    final response = await apiClient.post(
      AppUrls.consumptionDashboard,
      data: body,
    );

    kPrint('[ConsumptionService] Status: ${response.statusCode}');
    kPrint('[ConsumptionService] Body: ${response.body}');

    final jsonData = response.body;

    if (jsonData['status'] != 'Success') {
      throw Exception(
        'API error: ${jsonData['message'] ?? 'Unknown error'}',
      );
    }

    HelperMethods.printLongString(
      '[ConsumptionService] fetchDetail jsonData=$jsonData',
    );

    final list = (jsonData['output'] as List<dynamic>)
        .map(
          (item) =>
          FacilityDetailModel.fromJson(item as Map<String, dynamic>),
    )
        .toList();

    return list;
  }

  // ── GetProjectFinancialYear ───────────────────────────────────────────────
  Future<List<ProjectFinancialYear>> fetchFinancialYears() async {
    kPrint(
      '[ConsumptionService] fetchFinancialYears GET ${AppUrls.projectFinancialYear}',
    );

    final response = await apiClient.get(
      AppUrls.projectFinancialYear,
    );

    final jsonData = response.body;

    if (jsonData['status'] != 'Success') {
      throw Exception(
        'API error: ${jsonData['message'] ?? 'Unknown error'}',
      );
    }

    return (jsonData['output'] as List<dynamic>)
        .map(
          (item) =>
          ProjectFinancialYear.fromJson(item as Map<String, dynamic>),
    )
        .toList();
  }
}

