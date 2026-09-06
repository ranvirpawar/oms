import 'package:get/get.dart';



import '../../../../services/auth_manager.dart';
import '../model/facility_data_model.dart';
import '../service/facility_dashboard_service.dart';import 'package:lifenity_connect/utils/helper_functions/debug_print.dart';
class FacilityController extends GetxController {
  var isLoading = false.obs;
  var facilities = <FacilityData>[].obs;
  var selectedDate = DateTime.now().obs;

  final FacilityDashboardService facilityDashboardService = Get.put(FacilityDashboardService());

  var empId = ''.obs;
  var centerId = ''.obs;
  AuthManager authManager = Get.put(AuthManager());
  @override
  void onInit() {

    super.onInit();
    getUserdata();
  }
  void getUserdata() {
    authManager.getUserData().then((data) {
      CustomDebugFunction.log('📅user data from auth');
      if (data != null) {
        data.forEach((key, value) {
          CustomDebugFunction.log('$key: $value');
        });
        // Store empId if available
        final user = data['user'];
        if (user != null && user.containsKey('EmpCode')) {
          empId.value = user['EmpCode'].toString();
          centerId.value = user['CenterID'].toString();
          loadFacilityData();
          CustomDebugFunction.log('✅ empId set: ${empId.value}');
          CustomDebugFunction.log('✅ CenterID set: ${centerId.value}');
        } else {
          CustomDebugFunction.log('❌ EmpCode not found in user data');
        }
      } else {
        CustomDebugFunction.log('No user data found');
      }
    }).catchError((err) {
      CustomDebugFunction.log('Error loading user data: $err');
    });
  }
  void loadFacilityData() async {
    isLoading.value = true;
    try {
      // Format the date as 'yyyy/MM/dd'
      final formattedDate = "${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}";

      // Prepare input for the API
      final input = {
        'orderdate': formattedDate,
        'labcode': centerId.value,
        'Userid': empId.value,
      };

      // Call the API to fetch facility data
     final fetchedFacilityListData= await facilityDashboardService.getFacilityRegistrationData(input);
      facilities.assignAll(fetchedFacilityListData);

    } catch (e) {
      CustomDebugFunction.log('❌ Error loading facility data: $e');
      // SnackBarService.to.showMessage(message: 'Something went wrong please try later', backgroundColor: AppColors.secondary);

    } finally {
      isLoading.value = false;
    }
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadFacilityData(); // Reload data for selected date
  }

  void refreshData() {
    loadFacilityData();
  }
}