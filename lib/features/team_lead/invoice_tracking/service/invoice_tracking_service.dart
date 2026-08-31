import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:lifenity_connect/features/team_lead/invoice_tracking/model/billing_month_model.dart';
import 'package:lifenity_connect/network/app_urls.dart';

import 'dart:convert';

import '../../../../network/api_client.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/billing_year_model.dart';
import '../model/invoice_model.dart';
import '../model/new_facility_model.dart';
import '../model/new_facility_type_model.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

class InvoiceTrackingService {
  final APIClient apiClient = Get.find<APIClient>();

  // Fetch Billing Months
  Future<List<BillingMonth>> fetchBillingMonth(int year) async {
    try {
      final body = {
        'Year': year,
      };

      final response = await apiClient.post(
        AppUrls.getBillingMonth,
        data: body,
      );

      kPrint('✅ billing month response ${response.body}');

      final json = response.body;

      if (json['status'] != 'Success') {
        throw Exception(json['message'] ?? 'Failed');
      }

      final List<dynamic> list = json['output'] ?? [];
      return list.map((e) => BillingMonth.fromJson(e)).toList();
    } catch (e) {
      kPrint('❌ Error in getBilling Month: $e');
      throw Exception('Failed to get billing month: $e');
    }
  }

  // Fetch Year Dropdown
  Future<List<BillingYear>> fetchYearDropdown() async {
    try {
      final response = await apiClient.post(
        AppUrls.getYearDropDown,
        data : {}
      );

      kPrint('✅ year dropdown response ${response.body}');

      final json = response.body;

      if (json['status'] != 'Success') {
        throw Exception(json['message'] ?? 'Failed');
      }

      final List<dynamic> list = json['output'] ?? [];
      return list.map((e) => BillingYear.fromJson(e)).toList();
    } catch (e) {
      kPrint('❌ Error in getYear Dropdown: $e');
      throw Exception('Failed to get year dropdown: $e');
    }
  }

  // Get Facility Wise Invoice Status
  Future<List<InvoiceStatus>> getFacilityWiseInvoiceStatus({
    required int yearId,
    required int monthId,
    required int facilityCode,
  }) async {
    try {
      final formData = {
        'yearid': yearId,
        'monthid': monthId,
        'Facilitycode': facilityCode,
      };

      kPrint('url : ${AppUrls.facilityWiseInvoiceStatus}');

      final response = await apiClient.post(
        AppUrls.facilityWiseInvoiceStatus,
        data: formData,
      );

      kPrint('✅ invoice status response ${response.body}');

      final json = response.body;

      if (json['status'] != 'Success') {
        return [];
      }

      final List<dynamic> list = json['output'] ?? [];
      return list.map((e) => InvoiceStatus.fromJson(e)).toList();
    } catch (e) {
      kPrint(
        '❌ Error in getFacilityWiseInvoiceStatus: $e',
      );
      throw Exception('Failed to get invoice status: $e');
    }
  }

  // Get Invoice Stages
  Future<List<InvoiceStage>> getInvoiceStages(String invoiceId) async {
    try {
      // debugPrint
      kPrint('url : ${AppUrls.getInvoiceStages}');
      kPrint('invoiceId : $invoiceId');

      final response = await apiClient.post(
        AppUrls.getInvoiceStages,
        data: {
          'InvoiceId': invoiceId,
        },
      );

      kPrint('✅ invoice stages response ${response.body}');

      final json = response.body;

      if (json['status'] == 'Success') {
        final List<dynamic> list = json['output'] ?? [];
        return list.map((e) => InvoiceStage.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      kPrint('❌ Error in getInvoiceStages: $e');
      throw Exception('Failed to get invoice stages: $e');
    }
  }

  Future<bool> insertFacilityWiseInvoiceStatus({
    required int invoiceId,
    required int processId,
    required int userId,
    required String brNo,
    File? moPathFile,
  }) async {
    try {
      final formData = FormData();

      formData.fields.add(MapEntry('InvoiceId', invoiceId.toString()));
      formData.fields.add(MapEntry('ProcessId', processId.toString()));
      formData.fields.add(MapEntry('UserId', userId.toString()));
      formData.fields.add(MapEntry('Brno', brNo));

      kPrint('url : ${AppUrls.insertFacilityWiseInvoiceStatus}');
      kPrint('InvoiceId : $invoiceId');
      kPrint('ProcessId : $processId');
      kPrint('UserId : $userId');
      kPrint('Brno : $brNo');

      if (moPathFile != null) {
        final String fileName = moPathFile.path.split('/').last;

        formData.files.add(
          MapEntry(
            'File', // ← correct key
            await MultipartFile.fromFile(
              moPathFile.path,
              filename: fileName,
            ),
          ),
        );

        kPrint('📎 Uploading file: $fileName');
      } else {
        // No file → just don't add the File field
        // (or send empty if the API strictly requires the key)
        // formData.fields.add(const MapEntry('File', ''));
        kPrint('📎 No file provided for File');
      }

      final response = await apiClient.post(
        AppUrls.insertFacilityWiseInvoiceStatus,
        data: formData,
        isFormData: true,
      );

      kPrint(
        '✅ insert invoice status response ${response.body}',
      );

      final json = response.body;

      if (json['status']?.toString().toLowerCase() == 'success') {
        return true;
      } else {
        throw Exception(json['message'] ?? 'Failed');
      }
    } catch (e) {
      kPrint(
        '❌ Error in insertFacilityWiseInvoiceStatus: $e',
      );
      throw Exception('Failed to insert invoice status: $e');
    }
  }

  // get facility types
  Future<List<NewFacilityType>> getFacilityTypeList(String userId) async {
    try {
      final url = AppUrls.getFacilityTypes;
      final queryParams = {
        'UserID': userId,
      };

      final response = await apiClient.post(
        url,
        data: queryParams,
      );

      kPrint('Response data: ${response.body}');

      // Add null safety check
      if (response.body.isEmpty) {
        throw Exception('No data received from server');
      }

      final Map<String, dynamic> data = response.body;

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];

        return outputList
            .map((json) => NewFacilityType.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load facility types: '
              '${data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      kPrint('Error in getFacilityTypeList: $e');
      rethrow;
    }
  }

  // get facility list service class
  // In InvoiceTrackingService
  Future<List<NewFacilityModel>> getFacilityList({
    required String userId,
    required String ward,
    required int facilityTypeId,
  }) async {
    try {
      final url = AppUrls.fetchFacilityNamesByWardFType;

      final body = {
        'userid': userId,
        'Ward': ward,
        'Ftypid': facilityTypeId.toString(),
      };

      kPrint('Facility List URL: $url');
      kPrint('Facility List Body: $body');

      final response = await apiClient.post(
        url,
        data: body,
      );

      kPrint('Facility List Response: ${response.body}');

      final Map<String, dynamic> data = response.body;

      if (data['status'] == 'Success') {
        final List<dynamic> outputList = data['output'];

        return outputList
            .map((json) => NewFacilityModel.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      kPrint('Error in getFacilityList: $e');
      rethrow;
    }
  }
}
