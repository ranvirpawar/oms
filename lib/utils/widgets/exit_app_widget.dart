// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
//
// import '../../constants/app_assets.dart';
// import '../../features/auth/view/login_screen.dart';
// import '../../services/auth_manager.dart';
//
// class ExitDialog extends StatelessWidget {
//   final bool isBack;
//   final String appName;
//   final bool isLogOut;
//
//   ExitDialog({
//     super.key,
//     this.isBack = false,
//     this.appName = 'App Name',
//     this.isLogOut = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 Image.asset(AppAssets.risingTelanganaLogo,
//                     width: 26, height: 26),
//                 const SizedBox(width: 8),
//                 Text(
//                   appName,
//                   style: TextStyle(
//                     color: Theme.of(context).primaryColor,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _getDialogMessage(),
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.black87,
//                 height: 1.3,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: MaterialButton(
//                     onPressed: () => Navigator.of(context).pop(false),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: BorderSide(
//                         color: Theme.of(context).primaryColor.withOpacity(0.3),
//                       ),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     elevation: 0,
//                     highlightElevation: 0,
//                     color: Colors.transparent,
//                     child: Text(
//                       'Cancel',
//                       style: TextStyle(
//                         color: Theme.of(context).primaryColor,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: MaterialButton(
//                     onPressed: () => _handleAction(context),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     elevation: 0,
//                     highlightElevation: 0,
//                     color: Theme.of(context).primaryColor,
//                     child: Text(
//                       _getActionButtonText(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _getDialogMessage() {
//     if (isLogOut) {
//       return 'Are you sure you want to Log Out?';
//     }
//     return 'Are you sure you want to ${isBack ? 'go back' : 'exit the app'}?';
//   }
//
//   String _getActionButtonText() {
//     if (isLogOut) {
//       return 'Log Out';
//     }
//     return isBack ? 'Go Back' : 'Exit';
//   }
//
//   Future<void> _handleAction(BuildContext context) async {
//     Navigator.of(context).pop(true);
//     if (isLogOut) {
//       // await loginController.customerLogout();
//       // AuthManager().logoutUser();
//     } else if (isBack) {
//       Navigator.of(context).pop();
//     } else {
//       SystemNavigator.pop();
//     }
//   }
//
//   static Future<void> showExitDialog(
//     BuildContext context, {
//     bool isBack = false,
//     bool isLogOut = false,
//     String appName = 'App Name',
//   }) async {
//     final shouldExit = await showDialog<bool>(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) => ExitDialog(
//         isBack: isBack,
//         isLogOut: isLogOut,
//         appName: appName,
//       ),
//     );
//
//     if (shouldExit ?? false) {
//       if (isLogOut) {
//         //
//         final authManager = Get.find<AuthManager>();
//         authManager.logoutUser();
//         Get.offAll(
//           () => LoginScreen(),
//           transition: Transition.rightToLeft,
//           duration: const Duration(milliseconds: 500),
//         );
//       } else if (isBack) {
//         Navigator.of(context).pop();
//       } else {
//         SystemNavigator.pop();
//       }
//     }
//   }
// }
