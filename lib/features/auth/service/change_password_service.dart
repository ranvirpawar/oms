
import 'package:get/get.dart';

import '../../../network/api_client.dart';
import '../../../network/app_urls.dart';
import '../../../utils/ui_designs/liquid_snackbar.dart';



import '../../../utils/helper_functions/helper_methods.dart';


class ChangePasswordService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<bool> changePassword({
    required String empCode,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      kPrint('🔑 ChangePassword...');
      kPrint('➡️ URL: ${AppUrls.changePassword} | EmpCode: $empCode');

      final response = await apiClient.post(
        AppUrls.changePassword,
        data: {
          'OldPassword': oldPassword,
          'NewPassword': newPassword,
          'EmpCode': empCode,
        },
      );

      kPrint('⬅️ Status: ${response.statusCode} | Body: ${response.body}');

      final data = response.body;

      if (data['status'] == 'Success') {
        return true;
      } else {
        LiquidSnack.error(data['message'] ?? 'Password change failed');
        return false;
      }
    } catch (e) {
      kPrint('❌ ChangePasswordService error: $e');
      LiquidSnack.error('Something went wrong. Please try later.');
      rethrow;
    }
  }
}