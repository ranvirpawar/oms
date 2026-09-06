// services/phlebotomist_service.dart


import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/bag_transaction_model.dart';
import 'package:get/get.dart';

import '../model/phlebotomist_model.dart';

class PhlebotomistService {
  final APIClient apiClient = Get.find<APIClient>();

  // Step 1: Get Phlebotomist List by Designation
  Future<PhlebotomistListResponse> getPhlebotomistList(
      String desgId,
      ) async {
    try {
      kPrint('👥 Fetching phlebotomist list for designation: $desgId');

      final response = await apiClient.post(
        AppUrls.getPhlebotomistList,
        data: {
          'desgid': desgId,
        },
      );

      kPrint('✅ Phlebotomist list response: ${response.body}');

      return PhlebotomistListResponse.fromJson(response.body);
    } catch (e) {
      kPrint('❌ Error in getPhlebotomistList: $e');
      throw Exception('Failed to get phlebotomist list: $e');
    }
  }

  // Step 2: Get Bag Transaction by Barcode
  Future<BagTransactionResponse> getBagTransaction({
    required String bagcode,
    required int processId,
    required int userId,
  }) async {
    try {
      kPrint('📦 Fetching bag transaction for barcode: $bagcode');

      final response = await apiClient.post(
        AppUrls.getScanQRForAndTransactionID,
        data: {
          'Bagcode': bagcode,
          'Processid': processId.toString(),
          'userid': userId.toString(),
        },
      );

      kPrint('✅ Bag transaction response: ${response.body}');

      return BagTransactionResponse.fromJson(response.body);
    } catch (e) {
      kPrint('❌ Error in getBagTransaction: $e');
      throw Exception('Failed to get bag transaction: $e');
    }
  }

  // ADD THIS METHOD TO PhlebotomistService
  Future<HandoverStatusResponse> updateInitiateBagTransaction({
    required int processId,
    required int facilityCode,
    required int assignToUserId,
    required int userId,
    required int transactionId,
  }) async {
    try {
      kPrint(
        '🔄 Calling UpdateInnitiateBagTransaction for TransactionID: '
            '$transactionId',
      );

      final response = await apiClient.post(
        AppUrls.updateBagTransactionStatus,
        data: {
          'processid': processId.toString(),
          'Facilitycode': facilityCode.toString(),
          'Assignto': assignToUserId.toString(),
          'USerid': userId.toString(),
          'transactionid': transactionId.toString(),
        },
      );

      kPrint(
        '✅ UpdateInnitiateBagTransaction response: ${response.body}',
      );

      return HandoverStatusResponse.fromJson(response.body);
    } catch (e) {
      kPrint('❌ Error in updateInitiateBagTransaction: $e');
      rethrow;
    }
  }

  // Step 3: Insert Handover Status
  Future<HandoverStatusResponse> insertHandoverStatus({
    required int transactionId,
    required int processId,
    required int userId,
    required int handOverUserId,
  }) async {
    try {
      kPrint('✍️ Inserting handover status...');

      final position = await _getCurrentLocation();

      final response = await apiClient.post(
        AppUrls.insertBagTransactionStatus,
        data: {
          'TransactionID': transactionId.toString(),
          'processid': processId.toString(),
          'USerid': userId.toString(),
          'lats': position.latitude.toString(),
          'longs': position.longitude.toString(),
          'HandOverUserid': handOverUserId.toString(),
        },
      );

      kPrint('✅ Handover status response: ${response.body}');

      return HandoverStatusResponse.fromJson(response.body);
    } catch (e) {
      kPrint('❌ Error in insertHandoverStatus: $e');
      throw Exception('Failed to insert handover status: $e');
    }
  }

  // Get current location
  Future<Position> _getCurrentLocation() async {
    try {
      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      kPrint('❌ Error getting location: $e');


      return Position(
        latitude: 18.5115525,
        longitude: 73.7741556,
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

  // Error handling
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error. Please try again.';
    }
  }
}

/*class PhlebotomistService {
  final Dio _dio = Dio();


  // Step 1: Get Phlebotomist List by Designation
  Future<PhlebotomistListResponse> getPhlebotomistList(String desgId) async {
    try {
      debugPrint('👥 Fetching phlebotomist list for designation: $desgId');

      final response = await _dio.post(
        AppUrls.getPhlebotomistList,
        data: {'desgid': desgId},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      debugPrint('✅ Phlebotomist list response: ${response.data}');
      return PhlebotomistListResponse.fromJson(jsonDecode(response.data));
    } on DioException catch (e) {
      debugPrint('❌ DioException in getPhlebotomistList: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      debugPrint('❌ Error in getPhlebotomistList: $e');
      throw Exception('Failed to get phlebotomist list: $e');
    }
  }

  // Step 2: Get Bag Transaction by Barcode
  Future<BagTransactionResponse> getBagTransaction({
    required String bagcode,
    required int processId,
    required int userId,
  }) async {
    try {
      debugPrint('📦 Fetching bag transaction for barcode: $bagcode');

      final response = await _dio.post(
        AppUrls.getScanQRForAndTransactionID,
        data: {
          'Bagcode': bagcode,
          'Processid': processId.toString(),
          'userid': userId.toString(),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      debugPrint('✅ Bag transaction response: ${response.data}');
      return BagTransactionResponse.fromJson(jsonDecode(response.data));
    } on DioException catch (e) {
      debugPrint('❌ DioException in getBagTransaction: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      debugPrint('❌ Error in getBagTransaction: $e');
      throw Exception('Failed to get bag transaction: $e');
    }
  }
  // ADD THIS METHOD TO PhlebotomistService
  Future<HandoverStatusResponse> updateInitiateBagTransaction({
    required int processId,
    required int facilityCode,
    required int assignToUserId,
    required int userId,
    required int transactionId,
  }) async {
    try {
      debugPrint('🔄 Calling UpdateInnitiateBagTransaction for TransactionID: $transactionId');

      final response = await _dio.post(
        AppUrls.updateBagTransactionStatus,
        data: {
          'processid': processId.toString(),
          'Facilitycode': facilityCode.toString(),
          'Assignto': assignToUserId.toString(),
          'USerid': userId.toString(),
          'transactionid': transactionId.toString(),
        },
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      debugPrint('✅ UpdateInnitiateBagTransaction response: ${response.data}');
      return HandoverStatusResponse.fromJson(jsonDecode(response.data));
    } on DioException catch (e) {
      debugPrint('❌ DioException in updateInitiateBagTransaction: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      debugPrint('❌ Error in updateInitiateBagTransaction: $e');
      rethrow;
    }
  }

  // Step 3: Insert Handover Status
  Future<HandoverStatusResponse> insertHandoverStatus({
    required int transactionId,
    required int processId,
    required int userId,
    required int handOverUserId,
  }) async {
    try {
      debugPrint('✍️ Inserting handover status...');
      final position = await _getCurrentLocation();

      final response = await _dio.post(
        AppUrls.insertBagTransactionStatus,
        data: {
          'TransactionID': transactionId.toString(),
          'processid': processId.toString(),
          'USerid': userId.toString(),
          'lats': position.latitude.toString(),
          'longs': position.longitude.toString(),
          'HandOverUserid': handOverUserId.toString(),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      debugPrint('✅ Handover status response: ${response.data}');
      return HandoverStatusResponse.fromJson(jsonDecode(response.data));
    } on DioException catch (e) {
      debugPrint('❌ DioException in insertHandoverStatus: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      debugPrint('❌ Error in insertHandoverStatus: $e');
      throw Exception('Failed to insert handover status: $e');
    }
  }

  // Get current location
  Future<Position> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      // Return default location if unable to get current location
      return Position(
        latitude: 18.5115525,
        longitude: 73.7741556,
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

  // Error handling
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error. Please try again.';
    }
  }
}*/