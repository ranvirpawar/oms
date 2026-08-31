// views/patient_registration_dashboard.dart



// class PatientRegistrationDashboardList extends StatelessWidget {
//   const PatientRegistrationDashboardList({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(BagRegistrationController());
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: CustomAppBar(title: AppStrings.patientRegistration,
//         onBackPressed: RouteManager.redirectToHomeDashboard,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh,color: AppColors.surfaceContainer,),
//             onPressed: () => controller.refreshDashboard(),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(
//             child: CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//             ),
//           );
//         }
//
//         return RefreshIndicator(
//           onRefresh: controller.refreshDashboard,
//           color: AppColors.primary,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Status Card
//                 _buildStatusCard(controller),
//                 const SizedBox(height: 20),
//
//                 // Bag Details Card (if bag is open)
//                 if (controller.isBagOpen.value)...[_buildBagDetailsCard(controller),    const SizedBox(height: 20),
//                 ],
//
//                 // Action Buttons
//
//                 Padding
//                   (
//                     padding: EdgeInsets.only(bottom: 20),
//                     child: _buildActionButtons(controller)),
//
//
//                 // // Instructions Card
//                 // _buildInstructionsCard(controller),
//               ],
//             ),
//           ),
//         );
//       }),
//     );
//   }
//
//   Widget _buildStatusCard(BagRegistrationController controller) {
//     String statusText;
//     Color statusColor;
//     IconData statusIcon;
//
//     if (controller.isBagOpen.value) {
//       statusText = 'Bag Open';
//       statusColor = const Color(0xFF48BB78);
//       statusIcon = Icons.check_circle;
//     } else if (controller.isBagAssigned.value) {
//       statusText = 'Bag Assigned';
//       statusColor = const Color(0xFFED8936);
//       statusIcon = Icons.assignment;
//     } else {
//       statusText = 'No Bag Assigned';
//       statusColor = const Color(0xFFFC8181);
//       statusIcon = Icons.info_outline;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color:  statusColor.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(statusIcon, color: statusColor, size: 20),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Current Status',
//                   style: TextStyle(
//                     /*color: Colors.white,*/
//                     fontSize: 10,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   statusText,
//                   style: const TextStyle(
//                     /*color: Colors.white,*/
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (controller.isBagOpen.value)
//                   Text(
//                     'Bag: ${controller.bagStatusData.value!.bagcode}',
//                     style: const TextStyle(
//                       /* color: Colors.white70,*/
//                       fontSize: 12,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBagDetailsCard(BagRegistrationController controller) {
//     final bagCount = controller.bagCountData.value;
//
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Bag Details',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF2D3748),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatItem(
//                   'Capacity',
//                   bagCount?.bagcapacity.toString() ?? '0',
//                   Icons.all_inbox,
//                   const Color(0xFF4299E1),
//                 ),
//               ),
//               Expanded(
//                 child: _buildStatItem(
//                   'Occupied',
//                   bagCount?.tubecount.toString() ?? '0',
//                   Icons.inventory_2,
//                   const Color(0xFFED8936),
//                 ),
//               ),
//               Expanded(
//                 child: _buildStatItem(
//                   'Vacant',
//                   bagCount?.spaceVacnt.toString() ?? '0',
//                   Icons.inbox,
//                   const Color(0xFF48BB78),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // Progress Bar
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Space Utilization',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFF718096),
//                     ),
//                   ),
//                   Text(
//                     '${((bagCount?.tubecount ?? 0) / (bagCount?.bagcapacity ?? 1) * 100).toStringAsFixed(0)}%',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF2D3748),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: LinearProgressIndicator(
//                   value: (bagCount?.tubecount ?? 0) /
//                       (bagCount?.bagcapacity ?? 1),
//                   backgroundColor: const Color(0xFFE2E8F0),
//                   valueColor: const AlwaysStoppedAnimation<Color>(
//                     Color(0xFF4299E1),
//                   ),
//                   minHeight: 8,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatItem(
//       String label, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(icon, color: color, size: 24),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             color: Color(0xFF718096),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActionButtons(BagRegistrationController controller) {
//     return Column(
//       children: [
//         // Open Bag Button (if assigned but not open)
//         if (controller.isBagAssigned.value && !controller.isBagOpen.value)
//           _buildPrimaryButton(
//             'Open Bag',
//             Icons.qr_code_scanner,
//                 () => Get.to(() => const ScanBagPage()),
//             AppColors.primary,
//           ),
//
//         // Patient Registration Button (if bag is open)
//         if (controller.isBagOpen.value) ...[
//           _buildPrimaryButton(
//             'Register Patient',
//             Icons.person_add, // todo ask correct bagId for patient registration
//                 (){RouteManager.navigateToPatientRegistration(controller.bagStatusData.value!.bagID.toString());},
//             AppColors.primary,
//           ),
//           const SizedBox(height: 12),
//           _buildSecondaryButton(
//             'Close Bag',
//             Icons.lock,
//             controller.closeBag,
//             AppColors.secondary,
//           ),
//         ],
//       ],
//     );
//   }
//
//   Widget _buildPrimaryButton(
//       String text, IconData icon, VoidCallback onPressed, Color color) {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           shadowColor: color.withOpacity(0.3),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 24),
//             const SizedBox(width: 12),
//             Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSecondaryButton(
//       String text, IconData icon, VoidCallback onPressed, Color color) {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: OutlinedButton(
//         onPressed: onPressed,
//         style: OutlinedButton.styleFrom(
//           foregroundColor: color,
//           side: BorderSide(color: color, width: 2),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 24),
//             const SizedBox(width: 12),
//             Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInstructionsCard(BagRegistrationController controller) {
//     List<String> instructions;
//
//     if (!controller.isBagAssigned.value) {
//       instructions = [
//         'No bag is currently assigned to you',
//         'Please accept the bag from your assigned bag section',
//         'Once assigned, you can scan and open the bag',
//       ];
//     } else if (!controller.isBagOpen.value) {
//       instructions = [
//         'Bag is assigned but not opened yet',
//         'Tap "Open Bag" to scan the bag QR code',
//         'After scanning, you can start patient registration',
//       ];
//     } else {
//       instructions = [
//         'Bag is open and ready for use',
//         'Tap "Register Patient" to add new patient samples',
//         'Monitor the bag capacity to avoid overflow',
//         'Close the bag when finished or when full',
//       ];
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             children: [
//               Icon(Icons.info_outline, color:AppColors.primary, size: 24),
//               SizedBox(width: 12),
//               Text(
//                 'Instructions',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF2D3748),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ...instructions.map((instruction) => Padding(
//             padding: const EdgeInsets.only(bottom: 12),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   margin: const EdgeInsets.only(top: 6),
//                   width: 6,
//                   height: 6,
//                   decoration: const BoxDecoration(
//                     color: AppColors.primary,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     instruction,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Color(0xFF718096),
//                       height: 1.5,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )),
//         ],
//       ),
//     );
//   }
// }
