import 'dart:convert';

import 'package:get/get.dart';

import '../network/api_client.dart';
import '../network/app_urls.dart';

/// Thrown when the tracking endpoint can't be reached or errors out —
/// controllers catch this to surface a friendly message without leaking
/// transport details.
class LocationTrackingException implements Exception {
  final String message;
  LocationTrackingException(this.message);

  @override
  String toString() => message;
}

/// START marks the beginning of the route (queue "Start Route" action),
/// END marks arrival at the patient's location (collection flow).
enum TrackingAction { start, end }

extension on TrackingAction {
  String get apiValue => this == TrackingAction.start ? 'START' : 'END';
}

/// Shared by the patient queue ("Start Route") and the sample collection
/// flow ("Arrived at Location") to push GPS pings to the backend while the
/// phlebotomist is en route to a patient.
class LocationTrackingService {
  final APIClient _apiClient = Get.find<APIClient>();

  /// Posts a single location ping. Returns `true` when the backend
  /// acknowledges the update, `false` when it rejects it (bad ids etc.).
  /// Throws [LocationTrackingException] on transport failures.
  Future<bool> sendTracking({
    required int orderAssignDetailId,
    required int sampleCollectionOrderId,
    required int userId,
    required TrackingAction action,
    required double latitude,
    required double longitude,
    required int createdBy,
  }) async {
    final body = {
      'OrderAssignDetailID': orderAssignDetailId,
      'SampleCollectionOrderID': sampleCollectionOrderId,
      'UserID': userId,
      'TrackingAction': action.apiValue,
      'Latitude': latitude,
      'Longitude': longitude,
      'CreatedBy': createdBy,
    };
    try {
      final response = await _apiClient.post(
        AppUrls.locationTracking,
        data: body,
      );
      final Map<String, dynamic> respBody = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      return (respBody['status'] as String?)?.toLowerCase() == 'success';
    } catch (_) {
      throw LocationTrackingException(
        'Unable to update location. Please check your connection and try again.',
      );
    }
  }
}
