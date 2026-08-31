// lib/services/connector_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../handover_to_phlebo/model/bag_transaction_model.dart';
import '../model/connector_model.dart';
import 'package:get/get.dart';
class ConnectorService {
  final APIClient apiClient = Get.find<APIClient>();

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

      final json = response.body;

      kPrint('✅ Connector list response: $json');

      if (json['status'] != 'Success') {
        kPrint('⚠️ Failed to fetch connector list: ${json['message']}');
        throw Exception(json['message'] ?? 'Failed');
      }

      final List<dynamic> list = json['output'] ?? [];

      kPrint('📦 Parsed ${list.length} connectors successfully');

      return list.map((e) => Connector.fromJson(e)).toList();
    } catch (e) {
      kPrint('❌ Error in getConnectorList: $e');
      throw Exception('Failed to get connector list: $e');
    }
  }

  // --------------------------------------------------------------
  // 2. Get transaction for a scanned barcode
  // --------------------------------------------------------------
  Future<List<BagTransaction>> getBagTransaction({
    required String bagcode,
    required int processId,
    required int userId,
  }) async {
    try {
      kPrint('🔍 Fetching bag transaction for barcode: $bagcode');

      final response = await apiClient.post(
        AppUrls.getScanQRForAndTransactionID,
        data: {
          'Bagcode': bagcode,
          'Processid': processId.toString(),
          'userid': userId.toString(),
        },
      );

      final json = response.body;

      kPrint('✅ Bag transaction response: $json');

      if (json['status'] != 'Success') {
        kPrint(
          '⚠️ Failed to fetch bag transaction: ${json['message']}',
        );
        throw Exception(json['message'] ?? 'Failed');
      }

      final List<dynamic> list = json['output'] ?? [];
      final all = list.map((e) => BagTransaction.fromJson(e)).toList();

      return all;
    } catch (e) {
      kPrint('❌ Error in getBagTransaction: $e');
      throw Exception('Failed to get bag transaction: $e');
    }
  }

  // --------------------------------------------------------------
  // 3. Initiate bag transaction (processid = 6)
  // --------------------------------------------------------------
  Future<void> initiateBagTransaction({
    required int processId,
    required int facilityCode,
    required int assignTo,
    required int userId,
    required int transactionId,
  }) async {
    try {
      kPrint('⚙️ Initiating bag transaction...');

      final url = AppUrls.updateBagTransactionStatus;
      kPrint('🌐 API URL: $url');

      final data = {
        'processid': '$processId',
        'Facilitycode': '$facilityCode',
        'Assignto': '$assignTo',
        'USerid': '$userId',
        'transactionid': '$transactionId',
      };

      kPrint('📤 Request data: $data');

      final response = await apiClient.post(
        AppUrls.updateBagTransactionStatus,
        data: data,
      );

      final json = response.body;

      kPrint('✅ Initiate bag transaction response: $json');

      if (json['status'] != 'Success') {
        kPrint(
          '⚠️ Failed to initiate bag transaction: ${json['message']}',
        );
        throw Exception(json['message'] ?? 'Failed');
      }

      kPrint('🎯 Bag transaction initiated successfully');
    } catch (e) {
      kPrint('❌ Error in initiateBagTransaction: $e');
      throw Exception('Failed to initiate bag transaction: $e');
    }
  }

  // --------------------------------------------------------------
  // 4. Final insert (handover)
  // --------------------------------------------------------------
  Future<void> insertHandoverStatus({
    required int transactionId,
    required int processId,
    required int userId,
    required int handOverUserId,
    required double lat,
    required double lng,
  }) async {
    try {
      kPrint('✍️ Inserting handover status...');

      final url = AppUrls.insertBagTransactionStatus;
      kPrint('🌐 API URL: $url');

      final data = {
        'TransactionID': '$transactionId',
        'processid': '$processId',
        'USerid': '$userId',
        'lats': '$lat',
        'longs': '$lng',
        'HandOverUserid': '$handOverUserId',
      };

      kPrint('📤 Request data: $data');

      final response = await apiClient.post(
        AppUrls.insertBagTransactionStatus,
        data: data,
      );

      final json = response.body;

      kPrint('✅ Handover status response: $json');

      if (json['status'] != 'Success') {
        kPrint(
          '⚠️ Failed to insert handover status: ${json['message']}',
        );
        throw Exception(json['message'] ?? 'Failed');
      }

      kPrint('🎯 Handover status inserted successfully');
    } catch (e) {
      kPrint('❌ Error in insertHandoverStatus: $e');
      throw Exception('Failed to insert handover status: $e');
    }
  }

  // --------------------------------------------------------------
  // Error Handling
  // --------------------------------------------------------------
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

/*class ConnectorService {
  final Dio _dio = Dio();

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

  // --------------------------------------------------------------
  // 2. Get transaction for a scanned barcode
  // --------------------------------------------------------------
  Future<List<BagTransaction>> getBagTransaction({
    required String bagcode,
    required int processId,
    required int userId,

  }) async {
    try {
      debugPrint('🔍 Fetching bag transaction for barcode: $bagcode');

      final res = await _dio.post(
        AppUrls.getScanQRForAndTransactionID,
        data: {
          'Bagcode': bagcode,
          'Processid': processId.toString(),
          'userid': userId.toString(),
        },
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      debugPrint('✅ Bag transaction response: ${res.data}');
      final json = res.data is String ? jsonDecode(res.data) : res.data;

      if (json['status'] != 'Success') {
        debugPrint('⚠️ Failed to fetch bag transaction: ${json['message']}');
        throw Exception(json['message'] ?? 'Failed');
      }

      final List<dynamic> list = json['output'] ?? [];
      final all = list.map((e) => BagTransaction.fromJson(e)).toList();




      return all;
    } on DioException catch (e) {
      debugPrint('❌ DioException in getBagTransaction: ${e.message}');
      throw Exception(_handleError(e));
    } catch (e) {
      debugPrint('❌ Error in getBagTransaction: $e');
      throw Exception('Failed to get bag transaction: $e');
    }
  }

  // --------------------------------------------------------------
  // 3. Initiate bag transaction (processid = 6)
  // --------------------------------------------------------------
  Future<void> initiateBagTransaction({
    required int processId,
    required int facilityCode,
    required int assignTo,
    required int userId,
    required int transactionId,
  }) async {
    try {
      debugPrint('⚙️ Initiating bag transaction...');
      final url = AppUrls.updateBagTransactionStatus;
      debugPrint('🌐 API URL: $url');

      final data = {
        'processid': '$processId',
        'Facilitycode': '$facilityCode',
        'Assignto': '$assignTo',
        'USerid': '$userId',
        'transactionid': '$transactionId',

      };

      debugPrint('📤 Request data: $data');


      final res = await _dio.post(
        AppUrls.updateBagTransactionStatus,
        data: data,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      debugPrint('✅ Initiate bag transaction response: ${res.data}');
      final json = res.data is String ? jsonDecode(res.data) : res.data;

      if (json['status'] != 'Success') {
        debugPrint('⚠️ Failed to initiate bag transaction: ${json['message']}');
        throw Exception(json['message'] ?? 'Failed');
      }

      debugPrint('🎯 Bag transaction initiated successfully');
    } on DioException catch (e) {
      debugPrint('❌ DioException in initiateBagTransaction: ${e.message}');
      throw Exception(_handleError(e));
    } catch (e) {
      debugPrint('❌ Error in initiateBagTransaction: $e');
      throw Exception('Failed to initiate bag transaction: $e');
    }
  }

  // --------------------------------------------------------------
  // 4. Final insert (handover)
  // --------------------------------------------------------------
  Future<void> insertHandoverStatus({
    required int transactionId,
    required int processId,
    required int userId,
    required int handOverUserId,
    required double lat,
    required double lng,
  }) async {
    try {


      debugPrint('✍️ Inserting handover status...');
      final url = AppUrls.insertBagTransactionStatus;
      debugPrint('🌐 API URL: $url');

      final data = {
        'TransactionID': '$transactionId',
        'processid': '$processId',
        'USerid': '$userId',
        'lats': '$lat',
        'longs': '$lng',
        'HandOverUserid': '$handOverUserId',


      };
       debugPrint('📤 Request data: $data');

      final res = await _dio.post(
        AppUrls.insertBagTransactionStatus,
        data: data,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      debugPrint('✅ Handover status response: ${res.data}');
      final json = res.data is String ? jsonDecode(res.data) : res.data;

      if (json['status'] != 'Success') {
        debugPrint('⚠️ Failed to insert handover status: ${json['message']}');
        throw Exception(json['message'] ?? 'Failed');
      }

      debugPrint('🎯 Handover status inserted successfully');
    } on DioException catch (e) {
      debugPrint('❌ DioException in insertHandoverStatus: ${e.message}');
      throw Exception(_handleError(e));
    } catch (e) {
      debugPrint('❌ Error in insertHandoverStatus: $e');
      throw Exception('Failed to insert handover status: $e');
    }
  }

  // --------------------------------------------------------------
  // Error Handling
  // --------------------------------------------------------------
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


