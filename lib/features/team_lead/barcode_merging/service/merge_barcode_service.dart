
import 'package:lifenity_connect/network/app_urls.dart';

import '../../../../network/api_client.dart';
import '../../../../utils/helper_functions/helper_methods.dart';

import '../model/merge_test_patient_model.dart';
import 'package:get/get.dart';


class MergeBarcodeService {
  final APIClient apiClient = Get.find<APIClient>();

  /// Looks up patient / visit metadata for a scanned or typed barcode
  /// (order id). Returns `null` when the API responds successfully but with
  /// an empty `output` array (i.e. "barcode not found"), rather than
  /// throwing — callers use this to show a friendly "not found" message.
  Future<MergeTestPatientModel?> fetchPatientDetails({
    required String orderId,
  }) async {
    final json = await _post(
      AppUrls.getPatientDetailsForMergingTest,
      body: {'orderid': orderId},
    );

    final output = json['output'] as List<dynamic>?;
    if (output == null || output.isEmpty) return null;

    return MergeTestPatientModel.fromJson(
      output.first as Map<String, dynamic>,
    );
  }

  /// Merges the sugar/glucose barcode into the primary barcode's order.
  /// Returns the success message from the API on success, throws on failure.
  Future<String> mergeBarcodes({
    required int primaryVisitCode,
    required String primaryOrderId,
    required int sugarVisitCode,
    required String glucoseOrderId,
  }) async {
    final json = await _post(
      AppUrls.mergeSugarBarcode,
      body: {
        'Primaryvisitcode': '$primaryVisitCode',
        'PrimaryOrderid': primaryOrderId,
        'SugarVisitcode': '$sugarVisitCode',
        'Glucoseorderid': glucoseOrderId,
      },
    );

    return json['message']?.toString() ?? 'Sugar test merged successfully.';
  }

  // ── Private shared POST helper (mirrors LiveTrackingService) ─────────────
  Future<Map<String, dynamic>> _post(
      String url, {
        required Map<String, dynamic> body,
      }) async {
    kPrint('[MergeBarcodeService] POST $url  body=$body');

    try {
      final response = await apiClient.post(
        url,
        data: body,
      );

      kPrint('[MergeBarcodeService] Response: ${response.body}');

      return response.body;
    } catch (e) {
      kPrint('[MergeBarcodeService] Error: $e');
      rethrow;
    }
  }
}
