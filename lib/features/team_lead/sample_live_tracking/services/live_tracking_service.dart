import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:lifenity_connect/network/app_urls.dart';


import '../../../../network/api_client.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/bag_model.dart';
import '../model/facility_model.dart';
import '../model/get_bag_status_event_model.dart';
import '../model/sample_flow_summary_flow.dart';





class LiveTrackingService {
  final APIClient apiClient = Get.find<APIClient>();

  // ── Type 1 — funnel summary (Open bag / Collected / Handover / Accepted…) ──
  Future<SampleFlowSummaryModel> fetchStatusSummary({
    required String fromDate,
    required String toDate,
    required String userId,
  }) async {
    final json = await _post(
      url: AppUrls.getSampleLiveTrackingRb,
      body: {
        'type': '1',
        'fromdate': fromDate,
        'todate': toDate,
        'userid': userId,
      },
    );

    return SampleFlowSummaryModel.fromJson(
      (json['output'] as List<dynamic>).first as Map<String, dynamic>,
    );
  }

  // ── Type 3 — facility list with RB / status / TAT details ──────────────────
  Future<List<FacilityModel>> fetchFacilities({
    required String fromDate,
    required String toDate,
    required String userId,
  }) async {
    final json = await _post(
      url: AppUrls.getSampleLiveTrackingRb,
      body: {
        'type': '3',
        'fromdate': fromDate,
        'todate': toDate,
        'userid': userId,
      },
    );

    return (json['output'] as List<dynamic>)
        .map((e) => FacilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Type 4 — flat bag list with contact person / TAT (Bags tab) ────────────
  Future<List<BagModel>> fetchBags({
    required String fromDate,
    required String toDate,
    required String userId,
  }) async {
    try {
      final json = await _post(
        url: AppUrls.getSampleLiveTrackingRb,
        body: {
          'type': '4',
          'fromdate': fromDate,
          'todate': toDate,
          'userid': userId,
        },
      );

      return (json['output'] as List<dynamic>)
          .map((e) => BagModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      kPrint('[LiveTrackingService] fetchBags failed: $e');
      return <BagModel>[];
    }
  }

  // ── Drill-down — status timeline (type 1) + tube contents (type 2) ─────────
  // NOTE: add this endpoint to your AppUrls class:

  // Facility cards pass the real facilityCode; bag cards (which don't carry
  // one) pass 0, per the API's expectation.
  Future<BagDrillDownModel> fetchBagDetails({
    required int facilityCode,
    required String bagcode,
    required String visitDate,
  }) async {
    final results = await Future.wait([
      _post(
        url: AppUrls.getBagDetailsRbTrackingDashboard,
        body: {
          'type': '1',
          'facilitycode': '$facilityCode',
          'Bagcode': bagcode,
          'Visitdate': visitDate,
        },
      ),
      _post(
        url: AppUrls.getBagDetailsRbTrackingDashboard,
        body: {
          'type': '2',
          'facilitycode': '$facilityCode',
          'Bagcode': bagcode,
          'Visitdate': visitDate,
        },
      ),
    ]);

    final statusEvents = (results[0]['output'] as List<dynamic>)
        .map((e) => BagStatusEventModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final tubeContents = (results[1]['output'] as List<dynamic>)
        .map((e) => TubeContentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return BagDrillDownModel(
      statusEvents: statusEvents,
      tubeContents: tubeContents,
    );
  }

  // ── Private shared POST helper ──────────────────────────────────────────────
  Future<Map<String, dynamic>> _post({
    required String url,
    required Map<String, String> body,
  }) async {
    kPrint('[LiveTrackingService] POST $url  body=$body');

    final response = await apiClient.post(
      url,
      data: body,
    );

    kPrint('[LiveTrackingService] Body:   ${response.body}');

    final jsonData = response.body;

    if (jsonData['status'] != 'Success') {
      throw Exception(
        'API error: ${jsonData['message'] ?? 'Unknown error'}',
      );
    }

    return jsonData;
  }
}

/*class LiveTrackingService {
  // ── Type 1 — funnel summary (Open bag / Collected / Handover / Accepted…) ──
  Future<SampleFlowSummaryModel> fetchStatusSummary({
    required String fromDate,
    required String toDate,
    required String userId,
  }) async {
    final json = await _post(
      uri: Uri.parse(AppUrls.getSampleLiveTrackingRb),
      body: {'type': '1', 'fromdate': fromDate, 'todate': toDate, 'userid': userId},
    );
    return SampleFlowSummaryModel.fromJson(
      (json['output'] as List<dynamic>).first as Map<String, dynamic>,
    );
  }

  // ── Type 3 — facility list with RB / status / TAT details ──────────────────
  Future<List<FacilityModel>> fetchFacilities({
    required String fromDate,
    required String toDate,
    required String userId,
  }) async {
    final json = await _post(
      uri: Uri.parse(AppUrls.getSampleLiveTrackingRb),
      body: {'type': '3', 'fromdate': fromDate, 'todate': toDate, 'userid': userId},
    );
    return (json['output'] as List<dynamic>)
        .map((e) => FacilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Type 4 — flat bag list with contact person / TAT (Bags tab) ────────────
  Future<List<BagModel>> fetchBags({
    required String fromDate,
    required String toDate,
    required String userId,
  }) async {
    try {
      final json = await _post(
        uri: Uri.parse(AppUrls.getSampleLiveTrackingRb),
        body: {
          'type': '4',
          'fromdate': fromDate,
          'todate': toDate,
          'userid': userId,
        },
      );

      return (json['output'] as List<dynamic>)
          .map((e) => BagModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      kPrint('[LiveTrackingService] fetchBags failed: $e');
      return <BagModel>[];
    }
  }

  // ── Drill-down — status timeline (type 1) + tube contents (type 2) ─────────
  // NOTE: add this endpoint to your AppUrls class:

  // Facility cards pass the real facilityCode; bag cards (which don't carry
  // one) pass 0, per the API's expectation.
  Future<BagDrillDownModel> fetchBagDetails({
    required int facilityCode,
    required String bagcode,
    required String visitDate,
  }) async {
    final uri = Uri.parse(AppUrls.getBagDetailsRbTrackingDashboard);

    final results = await Future.wait([
      _post(uri: uri, body: {
        'type': '1',
        'facilitycode': '$facilityCode',
        'Bagcode': bagcode,
        'Visitdate': visitDate,
      }),
      _post(uri: uri, body: {
        'type': '2',
        'facilitycode': '$facilityCode',
        'Bagcode': bagcode,
        'Visitdate': visitDate,
      }),
    ]);

    final statusEvents = (results[0]['output'] as List<dynamic>)
        .map((e) => BagStatusEventModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final tubeContents = (results[1]['output'] as List<dynamic>)
        .map((e) => TubeContentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return BagDrillDownModel(statusEvents: statusEvents, tubeContents: tubeContents);
  }

  // ── Private shared POST helper ──────────────────────────────────────────────
  Future<Map<String, dynamic>> _post({
    required Uri uri,
    required Map<String, String> body,
  }) async {
    kPrint('[LiveTrackingService] POST $uri  body=$body');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    kPrint('[LiveTrackingService] Status: ${response.statusCode}');
    kPrint('[LiveTrackingService] Body:   ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: Failed to load live tracking data');
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    if (jsonData['status'] != 'Success') {
      throw Exception('API error: ${jsonData['message'] ?? 'Unknown error'}');
    }

    return jsonData;
  }
}*/
