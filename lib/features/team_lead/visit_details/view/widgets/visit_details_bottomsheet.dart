import 'package:flutter/material.dart';
import 'package:lifenity_connect/componenents/info_row_widget.dart';

import '../../../../../constants/app_assets.dart';
import '../../model/visit_model.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VisitDetailsBottomSheet extends StatelessWidget {
  final VisitData visit;

  const VisitDetailsBottomSheet({super.key, required this.visit});

  // Convert HTTP to HTTPS for the image URL
  String _ensureHttps(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _ensureHttps(visit.photoPath);

    return Container(
      // height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Center Information Section
            _buildDetailSection('Visit Information', [
              Row(
                children: [
                  Expanded(
                      child: InfoRow(
                          icon: AppAssets.facility,
                          title: 'Facility Name',
                          value: visit.centerLabName)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: InfoRow(
                          icon: AppAssets.fileNoteIcon,
                          title: 'Type',
                          value: visit.centerTypName)),
                ],
              ),
              Row(children: [
                Expanded(
                  child: InfoRow(
                      icon: AppAssets.doctor,
                      title: 'Doctor Name',
                      value: visit.fullName),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoRow(
                      icon: AppAssets.location,
                      title: 'District',
                      value: visit.distName),
                ),
              ]),

              // mobile number and date and time
              Row(
                children: [
                  Expanded(
                    child: InfoRow(
                        icon: AppAssets.mobileIcon,
                        title: 'Mobile Number',
                        value: visit.mobileNo),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoRow(
                        icon: AppAssets.calendarClockIcon,
                        title: 'Date & Time',
                        value: visit.createdOn),
                  ),
                ],
              )
            ]),

            if (visit.remark.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection('Remarks', [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    visit.remark,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            // visit photo landscape in middle of the screen
            if (visit.photoPath.isNotEmpty)
              Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _ensureHttps(visit.photoPath),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) {
                        debugPrint('Visit photo loading error: $error for URL: $url');
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: SvgPicture.asset(
                              AppAssets.infoIcon,
                              width: 48,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

           /* // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {

                    },
                    icon: SvgPicture.asset(
                      AppAssets.location,
                      width: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    label: const Text('View on Map'),
                    style: OutlinedButton.styleFrom(


                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              ],
            ),*/

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            )),
      ],
    );
  }

  Widget _buildDetailRow(String iconPath, String label, String value) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 16),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}
