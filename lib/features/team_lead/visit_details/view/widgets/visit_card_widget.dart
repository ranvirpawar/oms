
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifenity_connect/componenents/info_row_widget.dart';
import 'package:lifenity_connect/constants/app_assets.dart';

import '../../../../../constants/app_strings.dart';
import '../../model/visit_model.dart';





class VisitCardWidget extends ConsumerWidget {
  final VisitData visit;
  final VoidCallback onTap;

  const VisitCardWidget({
    super.key,
    required this.visit,
    required this.onTap,
  });

  /// Extract only time (HH:mm:ss) from dd/MM/yyyy HH:mm:ss
  String _extractTime(String dateTime) {
    if (dateTime.contains(' ')) {
      return dateTime.split(' ').last; // take last part = time
    }
    return dateTime; // fallback if format unexpected
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
              highlightColor: Theme.of(context).primaryColor.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Facility Name
                    InfoRow(
                      icon: AppAssets.facility,
                      title: AppStrings.facilityName,
                      value: visit.centerLabName,
                    ),
                    const SizedBox(height: 6),

                    // Type + Time
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: InfoRow(
                            icon: AppAssets.fileNoteIcon,
                            title: 'Type',
                            value: visit.centerTypName,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: InfoRow(
                            icon: AppAssets.calendarClockIcon,
                            title: 'Time',
                            value: _extractTime(visit.createdOn),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




/*class VisitCardWidget extends ConsumerWidget {
  final VisitData visit;
  final VoidCallback onTap;

  const VisitCardWidget({
    Key? key,
    required this.visit,
    required this.onTap,
  }) : super(key: key);

  // Convert HTTP to HTTPS for the image URL
  String _ensureHttps(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
              highlightColor: Theme.of(context).primaryColor.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Facility Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                         InfoRow(
                                icon: AppAssets.facility,
                                title: AppStrings.facilityName,
                                value: visit.centerLabName),
                        // Facility Name
                        // Row(
                        //   children: [
                        //     // Facility Icon
                        //     SvgPicture.asset(
                        //       AppAssets.facility,
                        //       width: 16,
                        //       color: Theme.of(context).primaryColor,
                        //     ),
                        //     const SizedBox(width: 6),
                        //     Text(
                        //       visit.centerLabName,
                        //       style: const TextStyle(
                        //         fontWeight: FontWeight.w600,
                        //         fontSize: 14,
                        //         color: Colors.black87,
                        //       ),
                        //       maxLines: 1,
                        //       overflow: TextOverflow.ellipsis,
                        //     ),
                        //   ],
                        // ),
                        const SizedBox(height: 6),
                        // Type and Visited Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              AppAssets.calendarClockIcon,
                              width: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              visit.createdOn,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(width: 16),
                            // Type Icon and Text
                            SvgPicture.asset(
                              AppAssets.fileNoteIcon,
                              width: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              visit.centerTypName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Theme.of(context).primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Arrow Icon
                    SvgPicture.asset(
                      AppAssets.forwardIcon,
                      width: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}*/

