// bag_status_controller.dart

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../services/user_service.dart';
import '../../../auth/model/login_response_model.dart';
import '../model/bag_status_model.dart';
import '../service/bag_status_service.dart';
class BagStatusController extends GetxController {
  final BagStatusService _service = Get.put(BagStatusService());
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<String> userId = ''.obs;
  final UserService userService = Get.put(UserService());

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // 🔹 MASTER LIST (Data from API)
  final RxList<BagGroup> bagGroups = <BagGroup>[].obs;

  // 🔹 DISPLAY LIST (Data shown on UI)
  final RxList<BagGroup> filteredBagGroups = <BagGroup>[].obs;

  // 🔹 Search Controller to manage text input
  final TextEditingController searchController = TextEditingController();

  // 🔹 AVAILABLE BAGS (New List)



  final RxList<BagTransaction> availableBags = <BagTransaction>[].obs;
  final RxList<BagTransaction> filteredAvailableBags = <BagTransaction>[].obs;
  final TextEditingController availableSearchController = TextEditingController(); // For available page

  bool get hasBags => filteredBagGroups.isNotEmpty; // Update to check filtered list

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  @override
  void onClose() {
    searchController.dispose(); // Clean up
    super.onClose();
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        loadBagStatus();
        debugPrint('✅ [Controller] User data loaded: ${user.value?.name}');
      } else {
        debugPrint('❌ [Controller] Failed to load user data');
      }
    } catch (e) {
      debugPrint('❌ [Controller] Error loading user: $e');
    }
  }

  Future<void> loadBagStatus() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.fetchBagStatus(userId.value);
      final allData = response.output;

      // 1. Store data in Master List
      bagGroups.value = _service.groupAndSortTransactions(response.output);

      // 2. Initialize Display List (and re-apply any existing search text if refreshing)
      filterBags(searchController.text);
      // 2. Process Available Bags (Flat List)
      availableBags.value = _service.getAvailableBags(allData);
      filterAvailableBags(availableSearchController.text);

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  Future<void> refreshBagStatus() async {
    await loadBagStatus();
  }

  // 🔹 SEARCH LOGIC
  void filterBags(String query) {
    if (query.isEmpty) {
      // If search is empty, show all bags
      filteredBagGroups.value = bagGroups;
    } else {
      // Filter logic: Check if bagcode contains the query
      // This works for "Last 4 digits" OR "Full Number" automatically
      filteredBagGroups.value = bagGroups.where((group) {
        return group.bagcode.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    debugPrint('🔍 [Controller] Search "$query" found ${filteredBagGroups.length} items');
  }

  void filterAvailableBags(String query) {
    if (query.isEmpty) {
      filteredAvailableBags.value = availableBags;
    } else {
      filteredAvailableBags.value = availableBags.where((bag) {
        return bag.bagcode.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }
}


