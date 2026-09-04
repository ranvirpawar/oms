// // incomplete_collection_section.dart
// //
// // Renders one block per sample marked "Not Collected": a reason table
// // (single-select, Yes/No styled per the reference screenshot) and a
// // remarks field. Only shown when at least one sample is incomplete.
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
//
// import '../../../../../theme/app_colors.dart';
// import '../../controller/sample_collection_controller.dart';
// import '../../model/sample_stype_style.dart';
//
// // incomplete_collection_section.dart
// //
// // Review list for samples with one or more tests flagged incomplete.
// // Reason/remarks capture happens up front in IncompleteTestsBottomSheet
// // (SampleItemCard's "Report unsuitable test(s)" menu action) — this
// // section is a read-back so the phlebotomist can confirm what's flagged
// // before submitting, undo a single test, or reopen the sheet to edit.
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../../../theme/app_colors.dart';
// import '../../controller/sample_collection_controller.dart';
// import '../../model/sample_collection_models.dart';
// import '../../model/sample_stype_style.dart';
//
// class IncompleteCollectionSection extends StatelessWidget {
//   final SampleCollectionController controller;
//
//   const IncompleteCollectionSection({super.key, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       // Any sample with at least one flagged test — whether it's fully
//       // unusable or just partially affected — belongs in this review list.
//       final flagged = controller.sampleEntries
//           .where((e) => e.testIncompleteMap.isNotEmpty)
//           .toList();
//       if (flagged.isEmpty) return const SizedBox.shrink();
//
//       final totalFlaggedTests =
//       flagged.fold<int>(0, (sum, e) => sum + e.testIncompleteMap.length);
//
//       return Container(
//         margin: const EdgeInsets.only(top: 4, bottom: 16),
//         decoration: BoxDecoration(
//           color: AppColors.bgCard,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppColors.redText.withOpacity(0.35)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
//               child: Row(
//                 children: [
//                   const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.redText),
//                   const SizedBox(width: 8),
//                   const Text(
//                     'Tests marked incomplete',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                   const Spacer(),
//                   Text(
//                     '$totalFlaggedTests test${totalFlaggedTests == 1 ? '' : 's'}',
//                     style: const TextStyle(
//                       fontSize: 11.5,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textTertiary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             for (final entry in flagged)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
//                 child: _IncompleteEntryBlock(
//                   entry: entry,
//                   controller: controller,
//                 ),
//               ),
//           ],
//         ),
//       );
//     });
//   }
// }
//
// class _IncompleteEntryBlock extends StatelessWidget {
//   final SampleBarcodeEntry entry;
//   final SampleCollectionController controller;
//
//   const _IncompleteEntryBlock({required this.entry, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     final style = SampleTypeStyles.forType(entry.sampleType);
//     return Obx(() {
//       // testIncompleteMap keys are testIds — resolve each back to its
//       // TestInfo (name/code) from the sample's own test list.
//       final rows = entry.testIncompleteMap.entries.map((mapEntry) {
//         final testId = mapEntry.key;
//         final info = mapEntry.value;
//         final testInfo = entry.tests.firstWhere(
//               (t) => t.testId == testId,
//           orElse: () => TestInfo(testId: testId, testCode: '', testName: 'Test #$testId'),
//         );
//         return (test: testInfo, info: info);
//       }).toList();
//
//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: AppColors.grayLight,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(style.fallbackIcon, size: 15, color: style.color),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     entry.sampleType,
//                     style: const TextStyle(
//                       fontSize: 13.5,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                 ),
//                 if (entry.isFullyUnusable)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: AppColors.redLight,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Text(
//                       'Not collected',
//                       style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.redText),
//                     ),
//                   ),
//                 const SizedBox(width: 6),
//                 TextButton(
//                   onPressed: () => controller.openIncompleteTestsSheet(entry),
//                   style: TextButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 6),
//                     minimumSize: const Size(0, 28),
//                     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   ),
//                   child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             for (final row in rows)
//               _FlaggedTestRow(
//                 testName: row.test.testName,
//                 testCode: row.test.testCode,
//                 reason: row.info.reason.reason,
//                 remarks: row.info.remarks,
//                 onRemove: () => controller.(entry, row.test.testId),
//               ),
//           ],
//         ),
//       );
//     });
//   }
// }
//
// /// One flagged test: name, the reason picked in the bottom sheet, and any
// /// free-text remarks — with a quick undo if it was flagged by mistake.
// class _FlaggedTestRow extends StatelessWidget {
//   final String testName;
//   final String testCode;
//   final String reason;
//   final String remarks;
//   final VoidCallback onRemove;
//
//   const _FlaggedTestRow({
//     required this.testName,
//     required this.testCode,
//     required this.reason,
//     required this.remarks,
//     required this.onRemove,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(top: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppColors.bgCard,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppColors.border),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   testCode.isNotEmpty ? '$testName ($testCode)' : testName,
//                   style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                   decoration: BoxDecoration(
//                     color: AppColors.redLight.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     reason,
//                     style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.redText),
//                   ),
//                 ),
//                 if (remarks.isNotEmpty) ...[
//                   const SizedBox(height: 6),
//                   Text(
//                     remarks,
//                     style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(width: 6),
//           Tooltip(
//             message: 'Remove flag',
//             child: InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: onRemove,
//               child: const Padding(
//                 padding: EdgeInsets.all(4),
//                 child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// /*class IncompleteCollectionSection extends StatelessWidget {
//   final SampleCollectionController controller;
//
//   const IncompleteCollectionSection({super.key, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final incomplete = controller.incompleteEntries;
//       if (incomplete.isEmpty) return const SizedBox.shrink();
//
//       return Container(
//         margin: const EdgeInsets.only(top: 4, bottom: 16),
//         decoration: BoxDecoration(
//           color: AppColors.bgCard,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppColors.redText.withOpacity(0.35)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
//               child: Row(
//                 children: const [
//                   Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.redText),
//                   SizedBox(width: 8),
//                   Text(
//                     'Samples not collected',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             for (final entry in incomplete)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
//                 child: _IncompleteEntryBlock(
//                   entry: entry,
//                   controller: controller,
//                 ),
//               ),
//           ],
//         ),
//       );
//     });
//   }
// }
//
// class _IncompleteEntryBlock extends StatelessWidget {
//   final SampleBarcodeEntry entry;
//   final SampleCollectionController controller;
//
//   const _IncompleteEntryBlock({required this.entry, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     final style = SampleTypeStyles.forType(entry.sampleType);
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.grayLight,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(style.fallbackIcon, size: 15, color: style.color),
//               const SizedBox(width: 6),
//               Text(
//                 entry.sampleType,
//                 style: const TextStyle(
//                   fontSize: 13.5,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Select the reason this sample was not collected.',
//             style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
//           ),
//           const SizedBox(height: 10),
//           _ReasonPicker(entry: entry, controller: controller),
//           const SizedBox(height: 10),
//           _buildRemarksField(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRemarksField() {
//     return TextField(
//       controller: entry.remarksController,
//       maxLines: 2,
//       style: const TextStyle(fontSize: 12.5),
//       decoration: InputDecoration(
//         hintText: 'Remarks (optional)',
//         hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
//         filled: true,
//         fillColor: AppColors.bgCard,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: AppColors.border),
//         ),
//       ),
//     );
//   }
// }
//
// class _ReasonPicker extends StatelessWidget {
//   final SampleBarcodeEntry entry;
//   final SampleCollectionController controller;
//
//   const _ReasonPicker({required this.entry, required this.controller});
//
//   void _openSheet(BuildContext context) {
//     Get.bottomSheet(
//       Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         padding: const EdgeInsets.only(bottom: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 10),
//             Container(
//               width: 36,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFD1D5DB),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Select reason',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//                 ),
//               ),
//             ),
//             Flexible(
//               child: Obx(
//                     () => ListView.separated(
//                   shrinkWrap: true,
//                   itemCount: controller.incompleteReasonOptions.length,
//                   separatorBuilder: (_, __) => const Divider(height: 1),
//                   itemBuilder: (context, index) {
//                     final reason = controller.incompleteReasonOptions[index];
//                     final isSelected = entry.selectedReason.value?.reasonId == reason.reasonId;
//                     return ListTile(
//                       title: Text(reason.reason, style: const TextStyle(fontSize: 14)),
//                       trailing: isSelected
//                           ? const Icon(Icons.check_rounded, color: AppColors.blue)
//                           : null,
//                       onTap: () {
//                         controller.selectIncompleteReason(entry, reason);
//                         Get.back();
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final selected = entry.selectedReason.value;
//       return GestureDetector(
//         onTap: () => _openSheet(context),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//           decoration: BoxDecoration(
//             color: AppColors.bgCard,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: selected == null ? AppColors.border : AppColors.blue),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   selected?.reason ?? 'Select a reason',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: selected == null ? AppColors.textMuted : AppColors.textPrimary,
//                   ),
//                 ),
//               ),
//               const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
//             ],
//           ),
//         ),
//       );
//     });
//   }
// }*/
