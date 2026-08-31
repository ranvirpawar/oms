// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lifenity_connect/componenents/c_textformfeild.dart';
// import 'package:lifenity_connect/constants/app_assets.dart';
// import 'package:lifenity_connect/features/runner_boy/collect_empty_bag/controller/empty_bag_controller.dart';
// import 'package:lifenity_connect/features/runner_boy/collect_empty_bag/view/widget/animated_scan_line.dart';
// import 'package:lifenity_connect/features/runner_boy/collect_empty_bag/view/widget/scan_line_painter.dart';
// import 'package:lifenity_connect/features/runner_boy/collect_empty_bag/view/widget/scanner_overlay_painter.dart';
// import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:get/get.dart';
//
//
//
//
// import 'dart:math' as math;
//
// import '../../../../theme/app_colors.dart';
//
//
// class CollectEmptyBagView extends StatelessWidget {
//   const CollectEmptyBagView({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(CollectEmptyBagController());
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//
//     return Scaffold(
//       appBar: CustomAppBar(
//         title: 'Collect Destination Bag',
//         actions: [
//           Obx(() => Padding(
//                 padding: const EdgeInsets.only(right: 10),
//                 child: IconButton(
//                   icon: Icon(
//                     controller.flashlightEnabled.value
//                         ? Icons.flash_on
//                         : Icons.flash_off,
//                     color: controller.flashlightEnabled.value
//                         ? Colors.yellow
//                         : AppColors.surfaceContainer,
//                   ),
//                   onPressed: controller.toggleFlashlight,
//                 ),
//               )),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Collapsible Scanner
//           Obx(() {
//             final hasBag = controller.bagDetail.value != null;
//             final isTyping = controller.isManualInputActive.value;
//
//             // Collapse when: has bag OR user is typing manually
//             final bool isCollapsed = hasBag || isTyping;
//
//             return AnimatedContainer(
//               duration: const Duration(milliseconds: 400),
//               curve: Curves.easeInOut,
//               height: isCollapsed ? 100 : MediaQuery.of(context).size.height * 0.45,
//               width: double.infinity,
//               child: Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.vertical(
//                         bottom: Radius.circular(isCollapsed ? 20 : 0)),
//                     child: MobileScanner(
//                       controller: controller.scannerController,
//                       onDetect: isTyping ? null : controller.onBarcodeDetected, // Optional: disable scan while typing
//                     ),
//                   ),
//
//                   // Scanner overlay only when NOT collapsed
//                   if (!isCollapsed)
//                     CustomPaint(
//                       painter: ScannerOverlayPainter(),
//                       child: const Center(
//                           child: AnimatedScanLine(height: 250, width: 250)),
//                     ),
//
//                   // Show "typing mode" overlay when collapsed due to typing
//                   if (isCollapsed)
//                     Container(
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                             colors: [Colors.black87, Colors.transparent],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter),
//                       ),
//                       padding: const EdgeInsets.all(12),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.keyboard, color: Colors.white, size: 28),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   isTyping ? "Manual Entry Mode" : "Scanned: ${controller.bagDetail.value!.bagcode}",
//                                   style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 15),
//                                 ),
//                                 Text(
//                                   isTyping
//                                       ? "Type barcode and press send"
//                                       : _getReasonText(controller.collectionReason.value),
//                                   style: const TextStyle(color: Colors.white70, fontSize: 12),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           if (isTyping)
//                             IconButton(
//                               icon: const Icon(Icons.clear, color: Colors.white),
//                               onPressed: () {
//                                 controller.manualBarcodeController.clear();
//                                 controller.manualInputFocusNode.unfocus();
//                                 controller.isManualInputActive.value = false;
//                                 controller.resetScanner();
//                               },
//                             )
//                           else
//                             IconButton(
//                               icon: const Icon(Icons.camera_alt, color: Colors.white),
//                               onPressed: controller.resetScanner,
//                             ),
//                         ],
//                       ),
//                     ),
//
//                   // Loading & hint
//                   if (controller.isLoading.value)
//                     Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
//
//                   if (!isCollapsed)
//                     Positioned(
//                       bottom: 4,
//                       left: 0,
//                       right: 0,
//                       child: Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 16),
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                         decoration: BoxDecoration(
//                             color: Colors.black54,
//                             borderRadius: BorderRadius.circular(12)),
//                         child: const Text('Align barcode within frame',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           }),
//          /* // Collapsible Scanner
//           Obx(() {
//             final hasBag = controller.bagDetail.value != null;
//
//             return AnimatedContainer(
//               duration: const Duration(milliseconds: 400),
//               curve: Curves.easeInOut,
//               height: hasBag ? 100 : MediaQuery.of(context).size.height * 0.45,
//               width: double.infinity,
//               child: Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.vertical(
//                         bottom: Radius.circular(hasBag ? 20 : 0)),
//                     child: MobileScanner(
//                       controller: controller.scannerController,
//                       onDetect: controller.onBarcodeDetected,
//                     ),
//                   ),
//                   if (!hasBag)
//                     CustomPaint(
//                       painter: ScannerOverlayPainter(),
//                       child: const Center(
//                           child: AnimatedScanLine(height: 250, width: 250)),
//                     ),
//                   if (hasBag)
//                     Container(
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                             colors: [Colors.black87, Colors.transparent],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter),
//                       ),
//                       padding: const EdgeInsets.all(12),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.inventory_2,
//                               color: Colors.white, size: 28),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                     "Scanned: ${controller.bagDetail.value!.bagcode}",
//                                     style: const TextStyle(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 15),
//                                     overflow: TextOverflow.ellipsis),
//                                 Text(
//                                     _getReasonText(
//                                         controller.collectionReason.value),
//                                     style: const TextStyle(
//                                         color: Colors.white70, fontSize: 12),),
//                               ],
//                             ),
//                           ),
//                           IconButton(
//                               icon: const Icon(Icons.camera_alt,
//                                   color: Colors.white),
//                               onPressed: controller.resetScanner),
//                         ],
//                       ),
//                     ),
//                   if (controller.isLoading.value)
//                     Container(
//                         color: Colors.black54,
//                         child:
//                             const Center(child: CircularProgressIndicator())),
//                   if (!hasBag)
//                     Positioned(
//                       bottom: 4,
//                       left: 0,
//                       right: 0,
//                       child: Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 16),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 12),
//                         decoration: BoxDecoration(
//                             color: Colors.black54,
//                             borderRadius: BorderRadius.circular(12)),
//                         child: const Text('Align barcode within frame',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500)),
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           }),*/
//
//           // Details Section
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: theme.scaffoldBackgroundColor,
//                 borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(30),
//                     topRight: Radius.circular(30)),
//               ),
//               padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
//               child: Obx(() {
//                 final bag = controller.bagDetail.value;
//
//                 return SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Purpose Selection
//                       Text('Purpose of Collection',
//                           style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: theme.colorScheme.onSurface)),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                               flex: 2,
//                               child: _reasonTile(
//                                   controller,
//                                   CollectionReason.handoverToPhlebotomist,
//                                   'Handover to Phlebotomist',
//                                   Icons.person_add)),
//                           const SizedBox(width: 12),
//                           Expanded(
//                               flex: 2,
//                               child: _reasonTile(
//                                   controller,
//                                   CollectionReason.collectSample,
//                                   'Collect Sample',
//                                   Icons.science)),
//                         ],
//                       ),
//                       const SizedBox(height: 24),
//
//                       // Manual Input
//                       if (bag == null)
//                         TextField(focusNode: controller.manualInputFocusNode,
//                           controller: controller.manualBarcodeController,
//                           textInputAction: TextInputAction.done,
//                           decoration: InputDecoration(
//                             hintText: "Enter barcode manually",
//                             prefixIcon: const Icon(Icons.qr_code_2),
//                             suffixIcon: IconButton(
//                                 icon: const Icon(Icons.send),
//                                 onPressed: controller.onManualSubmit),
//                             border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(16)),
//                             filled: true,
//                             fillColor:
//                                 isDark ? Colors.grey[800] : Colors.grey[100],
//                           ),
//                           onSubmitted: (_) => controller.onManualSubmit(),
//                         ),
//
//                       if (bag == null)
//                         const Padding(
//                           padding: EdgeInsets.only(top: 40),
//                           child: Center(
//                               child: Column(children: [
//                             Icon(Icons.qr_code_scanner,
//                                 size: 90, color: Colors.grey),
//                             SizedBox(height: 16),
//                             Text('Scan or enter bag code to continue',
//                                 style: TextStyle(
//                                     fontSize: 16, color: Colors.grey)),
//                           ],),),
//                         ),
//
//                       // Bag Details + Collect Button
//                       if (bag != null) ...[
//                         _buildRow("Bag Code", bag.bagcode, Icons.tag),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Expanded(child: _buildRow("Category", bag.category, Icons.category)),
//                             const SizedBox(width: 12),
//                             Expanded(child:  _buildRow(
//                                 "Capacity", bag.capacity.toString(), Icons.storage),),
//                           ],
//                         ),
//
//
//                         const SizedBox(height: 32),
//                         Obx(() => SizedBox(
//                               width: double.infinity,
//                               height: 56,
//                               child: ElevatedButton(
//                                 onPressed: controller.isSubmitting.value
//                                     ? null
//                                     : controller.collectBag,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: theme.colorScheme.primary,
//                                   shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(16)),
//                                   elevation: 6,
//                                 ),
//                                 child: controller.isSubmitting.value
//                                     ? const CircularProgressIndicator(
//                                         color: Colors.white)
//                                     : Text.rich(
//                                   TextSpan(
//                                     // First part: "Collect Bag – " (Inherits base style)
//                                     text: 'Collect Bag \n',
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color:AppColors.surfaceContainer,
//                                     ),
//                                     children: <InlineSpan>[
//
//                                       TextSpan(
//                                         text: _getReasonText(controller.collectionReason.value),
//                                         style: const TextStyle(
//                                           fontSize: 10,
//
//                                           fontWeight: FontWeight.normal,
//                                         ),
//                                       ),
//                                     ],
//
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                             )),
//                         const SizedBox(height: 12),
//                         OutlinedButton(
//                           onPressed: controller.resetScanner,
//                           style: OutlinedButton.styleFrom(
//                             side: BorderSide(
//                                 color: theme.colorScheme.primary, width: 2),
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(16)),
//                           ),
//                           child: const Text('Scan Another Bag',
//                               style: TextStyle(fontWeight: FontWeight.bold)),
//                         ),
//                       ],
//                     ],
//                   ),
//                 );
//               }),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _reasonTile(CollectEmptyBagController c, CollectionReason reason,
//       String title, IconData icon) {
//     final theme = Get.theme;
//     final isSelected = c.collectionReason.value == reason;
//
//     return GestureDetector(
//       onTap: () {
//         HapticFeedback.lightImpact();
//         c.collectionReason.value = reason;},
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 0),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? theme.colorScheme.primary.withOpacity(0.15)
//               : (theme.brightness == Brightness.dark
//                   ? Colors.grey[800]
//                   : Colors.grey[100]),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//               color:
//                   isSelected ? theme.colorScheme.primary : Colors.transparent,
//               width: 2),
//         ),
//         child: Text(
//           title,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//               fontSize: 10,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               color: isSelected ? theme.colorScheme.primary : null),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRow(String label, String value, IconData icon) {
//     final theme = Get.theme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: (theme.brightness == Brightness.dark
//                 ? Colors.grey[850]
//                 : Colors.grey[100])!
//             .withOpacity(0.7),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: theme.colorScheme.primary),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(label,
//                     style: TextStyle(fontSize: 10, color: Colors.grey[600])),
//                 const SizedBox(height: 4),
//                 Text(value,
//                     style: const TextStyle(
//                         fontSize: 14, fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _getReasonText(CollectionReason r) {
//     return r == CollectionReason.handoverToPhlebotomist
//         ? " for Handover to Phlebotomist "
//         : " for Sample collection ";
//   }
// }
