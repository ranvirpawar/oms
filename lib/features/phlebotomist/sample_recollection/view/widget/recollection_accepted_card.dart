import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../constants/app_assets.dart';
import '../../controller/sample_recollection_controller.dart';
import '../../model/test_recollection_model.dart';

class AcceptedCard extends StatelessWidget {
  final String orderId;
  final List<RecollectionTestListUpdated> tests;

  final SampleRecollectionController controller;
  final int srNo;


  const AcceptedCard({super.key, required this.orderId, required this.tests, required this.controller, required this.srNo});

  @override
  Widget build(BuildContext context) {
    return _buildGroupedAcceptedCard( context, orderId, tests, srNo);
  }
  Widget _buildGroupedAcceptedCard(
      BuildContext context, String orderId, List<RecollectionTestListUpdated> tests, int srNo) {
    final theme = Theme.of(context);
    final firstTest = tests.first;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.patient,
                            width: 16,
                            height: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              firstTest.patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Recollected',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Order IDs Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.barcodeIcon,
                            width: 16,
                            height: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              firstTest.orderId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        firstTest.gender,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // New Barcode
                if (firstTest.recollectedBarcode != null)
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.barcodeIcon,
                        width: 16,
                        height: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'New: ${firstTest.recollectedBarcode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // Recollected Date
                if (firstTest.recollectedDate != null)
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.calendarIcon,
                        width: 16,
                        height: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recollection Date: ${firstTest.recollectedDate}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // Tests - Collapsible
                Obx(() {
                  final expanded = controller.expandedCards.contains(orderId);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable header row
                      GestureDetector(
                        onTap: () => controller.toggleCardExpansion(orderId),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.testTube,
                              width: 16,
                              height: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tests.length > 1
                                    ? '${tests.length} Tests'
                                    : firstTest.testName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tests.length > 1)
                              Icon(
                                expanded ? Icons.expand_less : Icons.expand_more,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                      // Expanded test list
                      if (expanded && tests.length > 1) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: tests.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final test = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: idx < tests.length - 1 ? 8 : 0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        test.testName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  );
                }),


              ],
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                srNo.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
