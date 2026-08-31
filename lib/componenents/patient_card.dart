// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class PatientCard extends StatelessWidget {
//   final String name;
//   final String tag;
//   final String? profileImageUrl;
//   final List<List<InfoRowData>> infoRowGroups;
//   final bool showActionButton;
//   final String actionButtonText;
//   final IconData actionButtonIcon;
//   final VoidCallback? onActionButtonPressed;
//   final Color? tagColor;
//   final Color? buttonColor;
//   final Color? buttonTextColor;
//   final Color? cardColor;
//
//   const PatientCard({
//     Key? key,
//     required this.name,
//     required this.tag,
//     this.profileImageUrl,
//     required this.infoRowGroups,
//     this.showActionButton = false,
//     this.actionButtonText = 'View Details',
//     this.onActionButtonPressed,
//     this.actionButtonIcon = Icons.arrow_forward,
//     this.tagColor,
//     this.buttonColor,
//     this.buttonTextColor,
//     this.cardColor,
//   }) : super(key: key);
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       color: cardColor?? Theme.of(context).cardColor,
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Profile picture and name section
//             Row(
//               children: [
//                 Container(
//                   height: 40,
//                   width: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: Theme.of(context).primaryColor,
//                       width: 2,
//                     ),
//                   ),
//                   child: CircleAvatar(
//                     radius: 30,
//                     backgroundImage: profileImageUrl != null
//                         ? NetworkImage(profileImageUrl!)
//                         : null,
//                     child: profileImageUrl == null
//                         ? Icon(
//                       Icons.person,
//                       size: 30,
//                       color: Theme.of(context).colorScheme.primary,
//                     )
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Text(
//                   name,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: FittedBox(
//                     child: Text(
//                       tag,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: tagColor?? Theme.of(context).primaryColor,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//
//             // Dynamically build info rows from groups
//             for (var group in infoRowGroups) _buildInfoRowGroup(context, group),
//
//             // Action button (if enabled)
//             // Custom action button (if enabled)
//             if (showActionButton)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Align(
//                   alignment: Alignment.centerRight,
//                   child: IntrinsicWidth(
//                     child: GestureDetector(
//                       onTap: onActionButtonPressed,
//                       child: Container(
//                         height: 30,
//                         padding: const EdgeInsets.symmetric(horizontal: 10),
//                         decoration: BoxDecoration(
//                           color: buttonColor ?? Theme.of(context).primaryColor,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 4,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               actionButtonText,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: buttonTextColor ?? Colors.white,
//                               ),
//                             ),
//
//
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper method to build a group of info rows
//   Widget _buildInfoRowGroup(BuildContext context, List<InfoRowData> rowData) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: rowData.length == 1
//       // For a single InfoRow in the group
//           ? Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             rowData[0].icon,
//             color: Theme.of(context).primaryColor,
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   rowData[0].title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   rowData[0].value,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 13,
//                     height: 1.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       )
//       // For two InfoRows side by side
//           : Row(
//         children: [
//           // First info item
//           Expanded(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Icon(
//                   rowData[0].icon,
//                   color: Theme.of(context).primaryColor,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         rowData[0].title,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         rowData[0].value,
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 13,
//                           height: 1.5,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Second info item
//           Expanded(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Icon(
//                   rowData[1].icon,
//                   color: Theme.of(context).primaryColor,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         rowData[1].title,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         rowData[1].value,
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 13,
//                           height: 1.5,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Data class to hold row information
// class InfoRowData {
//   final IconData icon;
//   final String title;
//   final String value;
//
//   InfoRowData({
//     required this.icon,
//     required this.title,
//     required this.value,
//   });
// }
//
// // Modified InfoRow to support no-padding option for use in side-by-side layout
// class InfoRow extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String value;
//   final bool noPadding;
//
//   const InfoRow({
//     Key? key,
//     required this.icon,
//     required this.title,
//     required this.value,
//     this.noPadding = false,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: noPadding
//           ? EdgeInsets.zero
//           : const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             color: Theme.of(context).primaryColor,
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 13,
//                     height: 1.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Data class to hold row information
