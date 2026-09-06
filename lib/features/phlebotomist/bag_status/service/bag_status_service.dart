// bag_status_service.dart

import 'package:get/get.dart';

import 'package:lifenity_connect/network/app_urls.dart';
import '../../../../network/api_client.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/bag_status_model.dart';



class BagStatusService {
  final APIClient _apiClient = Get.find<APIClient>();

  Future<BagStatusResponse> fetchBagStatus(String userId) async {
    kPrint('🚀 [BagStatusService] Starting fetchBagStatus for userId: $userId');

    try {
      final body = {
        'userid': userId,
        'bagid': '0',
        'facilitycode': '0',
      };

      kPrint('📤 [BagStatusService] Sending POST Request to: ${AppUrls.getBagStatusTracking}');
      kPrint('📝 [BagStatusService] Request Body: $body');

      final result = await _apiClient.post(
        AppUrls.getBagStatusTracking,
        data: body,

      );

      kPrint('📥 [BagStatusService] Response Status Code: ${result.statusCode}');
      kPrint('✅ [BagStatusService] Success! Parsing JSON response...');
      kPrint('📄 [BagStatusService] Raw Response: ${result.data}');

      // result.data is already decoded by APIClient
      return BagStatusResponse.fromJson(
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : result.body,
      );
    } catch (e) {
      kPrint('💥 [BagStatusService] Exception caught: $e');
      throw Exception('Error fetching bag status: $e');
    }
  }

  // Group transactions by bagcode and sort by datetime
  List<BagGroup> groupAndSortTransactions(List<BagTransaction> transactions) {
    kPrint('🔄 [BagStatusService] grouping/sorting ${transactions.length} raw transactions');

    // Filter out available bags
    final activeBags = transactions.where((t) => !t.isAvailable).toList();
    kPrint('🔍 [BagStatusService] Filtered down to ${activeBags.length} active (not available) bags');

    // Group by bagcode
    final Map<String, List<BagTransaction>> grouped = {};
    for (var transaction in activeBags) {
      if (!grouped.containsKey(transaction.bagcode)) {
        grouped[transaction.bagcode] = [];
      }
      grouped[transaction.bagcode]!.add(transaction);
    }

    kPrint('📦 [BagStatusService] Created ${grouped.length} unique bag groups');

    // Sort transactions within each group by datetime (latest first)
    final List<BagGroup> bagGroups = [];
    grouped.forEach((bagcode, transactions) {
      transactions.sort((a, b) {
        final dateA = a.parsedDateTime;
        final dateB = b.parsedDateTime;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
      bagGroups.add(BagGroup(bagcode: bagcode, transactions: transactions));
    });

    // Sort groups by latest transaction datetime
    bagGroups.sort((a, b) {
      final dateA = a.latestTransaction.parsedDateTime;
      final dateB = b.latestTransaction.parsedDateTime;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    kPrint('🏁 [BagStatusService] Returning ${bagGroups.length} fully sorted groups');
    return bagGroups;
  }

  List<BagTransaction> getAvailableBags(List<BagTransaction> transactions) {
    // Logic: CurrentStage is "Available assign"
    return transactions.where((t) => t.isAvailable).toList();
  }
}