import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';


import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../handover_to_connector/model/connector_model.dart';
import '../model/collected_bag_model.dart';
import '../model/handover_submit_response.dart';





// ─────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────

class CollectedBagsService {
  final APIClient apiClient = Get.find<APIClient>();

  // 1. GetCollectedQRBagDetails
  Future<QRBagListResponse> getCollectedQRBagDetails(int userId) async {
    try {
      kPrint('📦 Fetching QR bag details for user: $userId');
      kPrint(AppUrls.getCollectedQRBagDetails);

      final response = await apiClient.post(
        AppUrls.getCollectedQRBagDetails,
        data: {
          'userid': userId.toString(),
        },
      );

      kPrint('📥 Raw response: ${response.body}');

      return QRBagListResponse.fromJson(response.body);
    } catch (e) {
      kPrint('❌ Error in getCollectedQRBagDetails: $e');
      throw Exception('Failed to get bag list: $e');
    }
  }

  // 2. SubmitQRBagToLabOrHandover
  // type = 1 → Submit to Lab (handoverUserId = userId)
  // type = 2 → Handover to Connector (handoverUserId = connector's id)
  Future<HandoverSubmitResponse> submitQRBagToLabOrHandover({
    required int type,
    required int fromSession,
    required int submittedBy,
    required int handoverUserId,
  }) async {
    try {
      kPrint(
        '🔬 Submitting bag | type=$type | session=$fromSession | by=$submittedBy | handoverTo=$handoverUserId',
      );

      final position = await _getCurrentLocation();
      kPrint('📍 url : ${AppUrls.submitQRBagToLabOrHandover}');

      final response = await apiClient.post(
        AppUrls.submitQRBagToLabOrHandover,
        data: {
          'type': type.toString(),
          'FromSession': fromSession.toString(),
          'SubmittedBy': submittedBy.toString(),
          'HanoverUserid': handoverUserId.toString(),
        },
      );

      kPrint('📥 Raw submission response: ${response.body}');

      return HandoverSubmitResponse.fromJson(response.body);
    } catch (e) {
      kPrint('❌ Error in submitQRBagToLabOrHandover: $e');
      throw Exception('Submission failed: $e');
    }
  }

  Future<Position> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      kPrint('⚠️ Location error, using fallback: $e');
      return Position(
        latitude: 18.5115871,
        longitude: 73.7741788,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  // --------------------------------------------------------------
  // 1. Get list of connectors
  // --------------------------------------------------------------
  Future<List<Connector>> getConnectorList(String desgid) async {
    try {
      kPrint('👥 Fetching connector list for designation: $desgid');

      final response = await apiClient.post(
        AppUrls.getPhlebotomistList,
        data: {
          'desgid': desgid,
        },
      );

      kPrint('✅ Connector list response: ${response.body}');

      final responseData = response.body;

      if (responseData['status'] != 'Success') {
        kPrint(
          '⚠️ Failed to fetch connector list: ${responseData['message']}',
        );
        throw Exception(responseData['message'] ?? 'Failed');
      }

      final List<dynamic> list = responseData['output'] ?? [];
      kPrint('📦 Parsed ${list.length} connectors successfully');

      return list.map((e) => Connector.fromJson(e)).toList();
    } catch (e) {
      kPrint('❌ Error in getConnectorList: $e');
      throw Exception('Failed to get connector list: $e');
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '⏳ Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return '🚨 Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return '❌ Request cancelled';
      default:
        return '🌐 Network error. Please try again.';
    }
  }
}
/*class CollectedBagsService {
  final Dio _dio = Dio();
  // 1. GetCollectedQRBagDetails
  Future<QRBagListResponse> getCollectedQRBagDetails(int userId) async {
    try {
      debugPrint('📦 Fetching QR bag details for user: $userId');
      debugPrint(AppUrls.getCollectedQRBagDetails);

      final response = await http.post(
        Uri.parse(AppUrls.getCollectedQRBagDetails),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'userid': userId.toString()},
      );

      debugPrint('📥 Raw response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QRBagListResponse.fromJson(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error in getCollectedQRBagDetails: $e');
      throw Exception('Failed to get bag list: $e');
    }
  }

  // 2. SubmitQRBagToLabOrHandover
  // type = 1 → Submit to Lab (handoverUserId = userId)
  // type = 2 → Handover to Connector (handoverUserId = connector's id)
  Future<HandoverSubmitResponse> submitQRBagToLabOrHandover({
    required int type,
    required int fromSession,
    required int submittedBy,
    required int handoverUserId,
  }) async {
    try {
      debugPrint(
          '🔬 Submitting bag | type=$type | session=$fromSession | by=$submittedBy | handoverTo=$handoverUserId');

      final position = await _getCurrentLocation();
      debugPrint('📍 url : ${AppUrls.submitQRBagToLabOrHandover}');


      final response = await http.post(
        Uri.parse(AppUrls.submitQRBagToLabOrHandover),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'type': type.toString(),
          'FromSession': fromSession.toString(),
          'SubmittedBy': submittedBy.toString(),
          'HanoverUserid': handoverUserId.toString(),

        },
      );

      debugPrint('📥 Raw submission response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HandoverSubmitResponse.fromJson(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error in submitQRBagToLabOrHandover: $e');
      throw Exception('Submission failed: $e');
    }
  }

  Future<Position> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('⚠️ Location error, using fallback: $e');
      return Position(
        latitude: 18.5115871,
        longitude: 73.7741788,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  // --------------------------------------------------------------
  // 1. Get list of connectors
  // --------------------------------------------------------------
  Future<List<Connector>> getConnectorList(String desgid) async {
    try {
      debugPrint('👥 Fetching connector list for designation: $desgid');

      final res = await _dio.post(
        AppUrls.getPhlebotomistList,
        data: {'desgid': desgid},
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      debugPrint('✅ Connector list response: ${res.data}');
      final json = res.data is String ? jsonDecode(res.data) : res.data;

      if (json['status'] != 'Success') {
        debugPrint('⚠️ Failed to fetch connector list: ${json['message']}');
        throw Exception(json['message'] ?? 'Failed');
      }

      final List<dynamic> list = json['output'] ?? [];
      debugPrint('📦 Parsed ${list.length} connectors successfully');
      return list.map((e) => Connector.fromJson(e)).toList();
    } on DioException catch (e) {
      debugPrint('❌ DioException in getConnectorList: ${e.message}');
      throw Exception(_handleError(e));
    } catch (e) {
      debugPrint('❌ Error in getConnectorList: $e');
      throw Exception('Failed to get connector list: $e');
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '⏳ Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return '🚨 Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return '❌ Request cancelled';
      default:
        return '🌐 Network error. Please try again.';
    }
  }
}*/


