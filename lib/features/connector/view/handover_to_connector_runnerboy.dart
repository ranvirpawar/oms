// // lib/views/handover_connector_view.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:flutter_svg/flutter_svg.dart';
//
// import '../../../../constants/app_assets.dart';
// import '../../../../theme/app_colors.dart';
// import '../../../../utils/animations/success_check_animation.dart';
// import '../../../../utils/widgets/custom_appbar.dart';
// import '../../../team_lead/visit_details/view/widgets/custom_dropdown.dart';
// import '../../collect_empty_bag/view/widget/animated_scan_line.dart';
// import '../../collect_empty_bag/view/widget/scanner_overlay_painter.dart';
// import '../../handover_to_phlebo/model/bag_transaction_model.dart';
// import '../controller/handover_to_connector_controller.dart';
//
//
// class HandoverConnectorView extends StatelessWidget {
//   HandoverConnectorView({super.key});
//
//   final HandoverConnectorController controller =
//   Get.put(HandoverConnectorController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: CustomAppBar(title: 'Handover to Connector'),
//       body: Obx(() {
//         if (controller.handoverState.value == HandoverState.processing &&
//             controller.handoverProgress.value > 0) {
//           return _buildProcessingView();
//         } else if (controller.handoverState.value == HandoverState.success) {
//           return _buildSuccessView();
//         }
//         return _buildMainView(context);
//       }),
//       bottomNavigationBar: Obx(() {
//         /*if (controller.handoverState.value == HandoverState.processing) {
//           return const SizedBox();
//         } else*/ if (controller.handoverState.value == HandoverState.success) {
//           return _buildSuccessBottomBar();
//         }
//         return _buildBottomBar();
//       }),
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // MAIN VIEW (bag-type dropdown + connector dropdown + scanner)
//   // -----------------------------------------------------------------
//   Widget _buildMainView(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // ==== 1. Bag Type Dropdown ====
//           _buildBagTypeSection(),
//
//
//
//           // ==== 2. Connector Selection ====
//           _buildConnectorSection(),
//
//           const SizedBox(height: 0),
//
//           // ==== 3. Scanner / Manual ====
//           Obx(() => controller.isScanning.value
//               ? _buildScannerSection()
//               : _buildManualEntrySection()),
//
//           const SizedBox(height: 16),
//
//           // ==== 4. Scanned Bags List ====
//           _buildScannedBagsList(),
//
//           const SizedBox(height: 100),
//         ],
//       ),
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // 1. Bag-Type dropdown
//   // -----------------------------------------------------------------
//   Widget _buildBagTypeSection() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2)),
//         ],
//       ),
//       child: Row(
//         children: [
//           SvgPicture.asset(AppAssets.medicalUnitIcon,
//               height: 22,
//               colorFilter:
//               const ColorFilter.mode(AppColors.primary, BlendMode.srcIn)),
//           const SizedBox(width: 12),
//           const Text('Bag Type',
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//           const Spacer(),
//           Obx(() => DropdownButton<String>(
//             value: controller.selectedBagType.value,
//             underline: const SizedBox(),
//             // decoration
//             icon: const Icon(Icons.keyboard_arrow_down,
//                 color: AppColors.primary, size: 24),
//             borderRadius: BorderRadius.circular(12),
//             dropdownColor: Colors.white,
//             items: controller.bagTypes
//                 .map((t) => DropdownMenuItem(value: t, child: Text(t)))
//                 .toList(),
//             onChanged: (v) => controller.selectedBagType.value = v!,
//           )),
//         ],
//       ),
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // 2. Connector selection (identical to phlebotomist but uses Connector)
//   // -----------------------------------------------------------------
//   Widget _buildConnectorSection() {
//     return Container(
//       margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             child: Row(
//               children: [
//                 SvgPicture.asset(
//                   AppAssets.connectorIcon,
//                   height: 22,
//                   colorFilter:
//                   const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text('Assign to Connector',
//                     style:
//                     TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             child: Obx(() {
//               if (controller.isLoading.value) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (controller.connectorList.isEmpty) {
//                 return Center(
//                   child: Column(
//                     children: [
//                       const Icon(Icons.person_off_outlined,
//                           size: 48, color: Colors.grey),
//                       const SizedBox(height: 12),
//                       const Text('No connectors available',
//                           style: TextStyle(color: Colors.grey)),
//                       TextButton.icon(
//                           onPressed: controller.fetchConnectorList,
//                           icon: const Icon(Icons.refresh),
//                           label: const Text('Retry')),
//                     ],
//                   ),
//                 );
//               }
//
//               return Column(
//                 children: [
//                   CustomDropdown(
//                     label: 'Select Connector',
//                     value: controller.selectedConnector.value?.userName ?? '',
//                     items: controller.connectorList
//                         .map((e) => e.userName)
//                         .toList(),
//                     onChanged: (v) {
//                       if (v != null && v.isNotEmpty) {
//                         final c = controller.connectorList
//                             .firstWhere((e) => e.userName == v);
//                         controller.selectConnector(c);
//                       }
//                     },
//                     iconPath: AppAssets.userIcon,
//                     isRequired: true,
//                   ),
//                   // ---- Selected connector details ----
//                   Obx(() {
//                     final c = controller.selectedConnector.value;
//                     if (c == null) return const SizedBox();
//                     return Container(
//                       margin: const EdgeInsets.only(top: 16),
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: AppColors.primary.withOpacity(0.05),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                             color: AppColors.primary.withOpacity(0.2)),
//                       ),
//                       child: Column(
//                         children: [
//                           _detailRow(Icons.location_city, 'Facility',
//                               c.facilityName),
//                           const SizedBox(height: 12),
//                           _detailRow(Icons.map, 'Ward', c.ward),
//                           const SizedBox(height: 12),
//                           _detailRow(Icons.business, 'Type', c.fType),
//                         ],
//                       ),
//                     );
//                   }),
//                 ],
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _detailRow(IconData icon, String label, String value) => Row(
//     children: [
//       Icon(icon, size: 16, color: AppColors.primary),
//       const SizedBox(width: 8),
//       Text('$label: ',
//           style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500)),
//       Expanded(
//           child: Text(value,
//               style: const TextStyle(
//                   fontSize: 13, fontWeight: FontWeight.w600))),
//     ],
//   );
//
//   // -----------------------------------------------------------------
//   // 3. Scanner (same as phlebotomist)
//   // -----------------------------------------------------------------
//   Widget _buildScannerSection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       height: 350,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: Stack(
//           children: [
//             MobileScanner(
//               controller: controller.scannerController,
//               onDetect: (capture) {
//                 final List<Barcode> barcodes = capture.barcodes;
//                 for (final barcode in barcodes) {
//                   if (barcode.rawValue != null) {
//                     controller.handleBarcodeScan(barcode.rawValue!);
//                     break;
//                   }
//                 }
//               },
//             ),
//
//
//             CustomPaint(
//               painter: ScannerOverlayPainter(),
//               child: Center(
//                 child: AnimatedScanLine(
//                   height: 200,
//                   width: 200,
//                 ),
//               ),
//             ),
//
//
//             // Controls
//             Positioned(
//               top: 16,
//               right: 16,
//               child: Row(
//                 children: [
//                   _buildIconButton(
//                     Icons.flash_on,
//                     controller.toggleFlash,
//                   ),
//                   const SizedBox(width: 8),
//                   _buildIconButton(
//                     Icons.close,
//                     controller.stopScanning,
//                   ),
//                 ],
//               ),
//             ),
//
//             // Instructions
//             Positioned(
//               bottom: 16,
//               left: 16,
//               right: 16,
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.7),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'Scan bag QR code',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.5),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white),
//         onPressed: onPressed,
//       ),
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // 4. Manual entry (same)
//   // -----------------------------------------------------------------
//   Widget _buildManualEntrySection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: SvgPicture.asset(
//                   AppAssets.barcodeIcon,
//                   colorFilter: const ColorFilter.mode(
//                       AppColors.primary, BlendMode.srcIn),
//                   height: 18,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 'Scan Bag',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           TextField(
//             controller: controller.barcodeController,
//             decoration: InputDecoration(
//               hintText: 'Enter bag barcode',
//               prefixIcon: const Icon(Icons.qr_code_rounded),
//             ),
//             onSubmitted: (_) => controller.processManualBarcode(),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: controller.startScanning,
//                   child: const Text("Scan Qr Code"),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: controller.processManualBarcode,
//                   child: const Text("Submit"),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // 5. Scanned bags list (same)
//   // -----------------------------------------------------------------
//   Widget _buildScannedBagsList() {
//     return Obx(() {
//       if (controller.scannedBags.isEmpty) {
//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16),
//           padding: const EdgeInsets.all(20),
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             children: [
//               Icon(
//                 Icons.shopping_bag_outlined,
//                 size: 64,
//                 color: Colors.grey.shade300,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'No bags scanned yet',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey.shade600,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Scan a bag to add it ',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade500,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }
//
//       return Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(
//                       Icons.check_circle_outline,
//                       color: Colors.green.shade600,
//                       size: 16,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     'Scanned Bags (${controller.scannedBags.length})',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF1A1F36),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Divider(height: 1),
//             ListView.separated(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               padding: const EdgeInsets.all(16),
//               itemCount: controller.scannedBags.length,
//               separatorBuilder: (context, index) => const SizedBox(height: 12),
//               itemBuilder: (context, index) {
//                 final bag = controller.scannedBags[index];
//                 return _buildBagCard(bag);
//               },
//             ),
//           ],
//         ),
//       );
//     });
//   }
//
//   Widget _buildBagCard(BagTransaction bag) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: const Duration(milliseconds: 300),
//       builder: (context, value, child) {
//         return Transform.scale(
//           scale: value,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF9FAFB),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFFE0E6ED)),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: SvgPicture.asset(
//                     AppAssets.medicalUnitIcon,
//                     colorFilter: const ColorFilter.mode(
//                         AppColors.primary, BlendMode.srcIn),
//                     height: 18,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         bag.bagcode,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1A1F36),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${bag.category} • Capacity: ${bag.capacity}',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => controller.removeBag(bag),
//                   icon: Icon(
//                     Icons.close,
//                     color: Colors.red.shade400,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // Bottom bar (same logic, just different button text)
//   // -----------------------------------------------------------------
//   Widget _buildBottomBar() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, -2)),
//         ],
//       ),
//       child: SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (controller.scannedBags.isNotEmpty)
//               Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 margin: const EdgeInsets.only(bottom: 12),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF9FAFB),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Total Bags',
//                         style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                             fontWeight: FontWeight.w500)),
//                     Text('${controller.scannedBags.length}',
//                         style: const TextStyle(
//                             fontSize: 18,
//                             color: Color(0xFF4F46E5),
//                             fontWeight: FontWeight.w700)),
//                   ],
//                 ),
//               ),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 // show circular progress bar while
//                 onPressed:
//                 controller.canHandover() ? controller.performHandover : null,
//                 child: controller.isLoading.value
//                     ? const CircularProgressIndicator(
//                   color: Colors.white,
//                 )
//                     : Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.send),
//                     const SizedBox(width: 8),
//                     Text(
//                       controller.canHandover()
//                           ? 'Handover Bags (${controller.scannedBags.length})'
//                           : 'Handover Bags',
//                       style: const TextStyle(
//                           fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // Success view (identical)
//   // -----------------------------------------------------------------
//   Widget _buildSuccessView() {
//     return Container(
//       color: Colors.white,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SuccessCheckAnimation(),
//             const SizedBox(height: 32),
//             const Text(
//               'Handover Successful!',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1A1F36),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             Obx(
//                   () => Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 40),
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF9FAFB),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: const Color(0xFFE0E6ED)),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Bags Handed Over',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         Text(
//                           '${controller.scannedBags.length}',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             color: Color(0xFF1A1F36),
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Divider(height: 24),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Handed to',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         Text(
//                           controller.selectedConnector.value?.userName ?? '',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Color(0xFF4F46E5),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//
//           ],
//         ),
//       ),
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // Success bottom bar – “Hand Over New Bag”
//   // -----------------------------------------------------------------
//   Widget _buildSuccessBottomBar() {
//     return Padding(
//       padding: const EdgeInsets.all(20.0),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: controller.reset,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF4F46E5),
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12)),
//             elevation: 0,
//           ),
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.send),
//               SizedBox(width: 8),
//               Text('Hand Over New Bag',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // -----------------------------------------------------------------
//   // Processing view (identical)
//   // -----------------------------------------------------------------
//   Widget _buildProcessingView() {
//     return Container(
//       color: Colors.white,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Stack(
//               alignment: Alignment.center,
//               children: [
//                 Obx(() => SizedBox(
//                   width: 120,
//                   height: 120,
//                   child: CircularProgressIndicator(
//                     value: controller.handoverProgress.value,
//                     strokeWidth: 6,
//                     backgroundColor: const Color(0xFFE0E6ED),
//                     valueColor: const AlwaysStoppedAnimation<Color>(
//                         Color(0xFF4F46E5)),
//                   ),
//                 )),
//                 TweenAnimationBuilder<double>(
//                   tween: Tween(begin: 0.0, end: 1.0),
//                   duration: const Duration(milliseconds: 1500),
//                   builder: (context, value, child) {
//                     return Transform.scale(
//                       scale: 0.8 + (value * 0.2),
//                       child: Icon(
//                         Icons.local_shipping_outlined,
//                         size: 50,
//                         color: const Color(0xFF4F46E5).withOpacity(0.8),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 32),
//             const Text(
//               'Handing Over Bags...',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1A1F36),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Obx(() => Text(
//               'Processing ${(controller.handoverProgress.value * controller.scannedBags.length).ceil()} of ${controller.scannedBags.length}',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade600,
//               ),
//             )),
//             const SizedBox(height: 24),
//             Obx(() => Text(
//               'To: ${controller.selectedConnector.value?.userName ?? ""}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Color(0xFF4F46E5),
//                 fontWeight: FontWeight.w600,
//               ),
//             )),
//           ],
//         ),
//       ),
//     );
//   }
// }