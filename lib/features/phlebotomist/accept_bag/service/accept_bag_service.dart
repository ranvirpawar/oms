// accept_bag_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lifenity_connect/network/app_urls.dart';
import 'dart:convert';

import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/accept_bag_model.dart';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../network/app_urls.dart';
import '../../../../network/api_client.dart'; // adjust path if needed

class AcceptBagService {
  final APIClient _apiClient = Get.find<APIClient>();

  // Step 1: Get Assigned Bags List
  Future<AssignedBagListResponse> getAssignedBagsList({
    required int phleboUserId,
    required int processId,
  }) async {
    try {
      kPrint('📋 Fetching assigned bags for user: $phleboUserId');

      final result = await _apiClient.post(
        AppUrls.assignedBagsForPhlebotomist,
        data: {
          'PhleboUserid': phleboUserId.toString(),
          'processid': processId.toString(),
        },
        // isJson: true (default) → application/json
      );

      kPrint('✅ Assigned bags list response: ${result.data}');

      return AssignedBagListResponse.fromJson(
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : result.body,
      );
    } catch (e) {
      kPrint('❌ Error in getAssignedBagsList: $e');
      throw Exception('Failed to get assigned bags list: $e');
    }
  }

  // Step 2: Scan QR and Get Transaction Details
  Future<BagQRTransactionResponse> scanBagQR({
    required String bagcode,
    required int processId,
    required int userId,
  }) async {
    try {
      kPrint('📷 Scanning QR for bag: $bagcode');

      final result = await _apiClient.post(
        AppUrls.getScanQRForAndTransactionID,
        data: {
          'Bagcode': bagcode,
          'Processid': processId.toString(),
          'userid': userId.toString(),
        },
      );

      kPrint('✅ QR scan response: ${result.data}');

      return BagQRTransactionResponse.fromJson(
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : result.body,
      );
    } catch (e) {
      kPrint('❌ Error in scanBagQR: $e');
      throw Exception('Failed to scan bag QR: $e');
    }
  }

  // Step 3: Accept Bag (Insert Transaction Status)
  Future<AcceptBagResponse> acceptBag({
    required int transactionId,
    required int processId,
    required int userId,
    required int handOverUserId,
  }) async {
    try {
      kPrint('✅ Accepting bag with transaction ID: $transactionId');

      final position = await _getCurrentLocation();

      final result = await _apiClient.post(
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

      kPrint('✅ Accept bag response: ${result.data}');

      return AcceptBagResponse.fromJson(
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : result.body,
      );
    } catch (e) {
      kPrint('❌ Error in acceptBag: $e');
      throw Exception('Failed to accept bag: $e');
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
      kPrint('❌ Error getting location: $e');
      // Return default location if unable to get current location
      return Position(
        latitude: 18.502186,
        longitude: 73.7971582,
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
}
