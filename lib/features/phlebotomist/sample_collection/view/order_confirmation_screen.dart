// order_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/constants/app_strings.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../theme/app_colors.dart';
import '../../patient_queue/model/patient_queue_model.dart';
import '../controller/sample_collection_controller.dart';
import '../model/sample_collection_models.dart';
import 'widgets/otp_verification_screen.dart';

class OrderConfirmationScreen extends GetView<SampleCollectionController> {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: const CustomAppBar(title: 'Order Details'),
      body: Obx(() {
        if (!controller.isOrderAccepted) {
          return _NotAcceptedView(patient: controller.assignedPatient);
        }

        if (controller.isLoadingOrder.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.orderLoadError.value.isNotEmpty) {
          return _ErrorState(
            message: controller.orderLoadError.value,
            onRetry: controller.fetchOrderDetails,
          );
        }
        final order = controller.orderDetails.value;
        if (order == null) return const SizedBox.shrink();

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _PatientHeaderCard(order: order),
                const SizedBox(height: 14),
                if (order.fastingRequired ||
                    order.specialInstructions.isNotEmpty)
                  _InstructionsCard(order: order),
                const SizedBox(height: 14),
                _SampleRequirementsCard(order: order),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ConfirmBar(controller: controller),
            ),
          ],
        );
      }),
    );
  }
}

class _PatientHeaderCard extends StatelessWidget {
  final OrderConfirmationDetails order;

  const _PatientHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary100,
                backgroundImage: (order.patient.photoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(order.patient.photoUrl!)
                    : null,
                child: (order.patient.photoUrl?.isNotEmpty ?? false)
                    ? null
                    : Text(
                        order.patient.name.isNotEmpty
                            ? order.patient.name.trim()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary800,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.patient.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.patient.age} • ${order.patient.gender} • Order #${order.orderId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _PriorityBadge(priority: order.priority),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: AppColors.blueText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.slotDateTime,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blueText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority.trim().isEmpty) return const SizedBox.shrink();
    final isHigh = priority.toLowerCase() == 'high';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHigh ? AppColors.redLight : AppColors.greenLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isHigh ? AppColors.redText : AppColors.greenText,
        ),
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final OrderConfirmationDetails order;

  const _InstructionsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: AppColors.amberText,
              ),
              SizedBox(width: 6),
              Text(
                'Collection Instructions',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (order.fastingRequired &&
              (order.fastingNote?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              order.fastingNote!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (order.specialInstructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final instruction in {
              for (final s in order.specialInstructions) s.instruction,
            })
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•  ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SampleRequirementsCard extends StatelessWidget {
  final OrderConfirmationDetails order;

  const _SampleRequirementsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tests (${order.totalTestCountReceived})',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${order.totalSampleTypes} sample${order.totalSampleTypes == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildGroups(),
        ],
      ),
    );
  }

  List<Widget> _buildGroups() {
    final widgets = <Widget>[];
    var serial = 0;
    for (var i = 0; i < order.sampleRequirements.length; i++) {
      final req = order.sampleRequirements[i];
      widgets.add(
        Row(
          children: [
            const Icon(
              Icons.science_outlined,
              size: 14,
              color: AppColors.tealText,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                req.volumeRequiredMl.isNotEmpty
                    ? '${req.sampleType} • ${req.volumeRequiredMl}'
                    : req.sampleType,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 6));
      for (final test in req.tests) {
        serial++;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '$serial.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    test.testName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (test.testCode.isNotEmpty)
                  Text(
                    test.testCode,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
      if (i != order.sampleRequirements.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }
}

class _ConfirmBar extends StatelessWidget {
  final SampleCollectionController controller;

  const _ConfirmBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          onPressed: () {
            controller.confirmAndCollect();
            Get.to(() => const OtpVerificationScreen());
          },
          child: const Text(
            'Confirm & Collect',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.redText,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _NotAcceptedView extends StatelessWidget {
  final AssignedPatient patient;

  const _NotAcceptedView({required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary100,
                    backgroundImage: (patient.avatarUrl?.isNotEmpty ?? false)
                        ? NetworkImage(patient.avatarUrl!)
                        : null,
                    child: (patient.avatarUrl?.isNotEmpty ?? false)
                        ? null
                        : Text(
                            patient.name.isNotEmpty
                                ? patient.name.trim()[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary800,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${patient.orderId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Shows the current status once, as requested.
                  // StatusBadge(status: patient.status, compact: true),
                ],
              ),
              const Divider(height: 24),
              if (patient.slotDateTime != null)
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppColors.blueText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(patient.slotDateTime!),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blueText,
                      ),
                    ),
                  ],
                ),
              if (patient.tests.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Tests',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < patient.tests.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${i + 1}.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            patient.tests[i],
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.amberLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.amberBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                size: 18,
                color: AppColors.amberText,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You need to accept this order first in order to start the collection.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
