// order_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_strings.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../theme/app_colors.dart';
import '../controller/sample_collection_controller.dart';
import '../model/sample_collection_models.dart';
import 'widgets/otp_verification_screen.dart';

class OrderConfirmationScreen extends GetView<SampleCollectionController> {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: const CustomAppBar(
        title: 'Order Details',
      ),
      body: Obx(() {
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
                if (order.fastingRequired || order.specialInstructions.isNotEmpty)
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
                            fontSize: 18),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.patient.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${order.patient.age} • ${order.patient.gender} • Order #${order.orderId}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
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
              const Icon(Icons.access_time_rounded, size: 15, color: AppColors.blueText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.slotDateTime,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.blueText),
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
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 17, color: AppColors.amberText),
              SizedBox(width: 6),
              Text('Collection Instructions',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          if (order.fastingRequired && (order.fastingNote?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(order.fastingNote!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
          ],
          if (order.specialInstructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final instruction in order.specialInstructions)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Expanded(
                      child: Text(instruction,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
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
          Text(
            'Required Samples (${order.totalSampleTypes})',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final req in order.sampleRequirements)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.science_outlined, size: 14, color: AppColors.tealText),
                      const SizedBox(width: 6),
                      Text(
                        req.volumeRequiredMl.isNotEmpty
                            ? '${req.sampleType} • ${req.volumeRequiredMl}'
                            : req.sampleType,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            elevation: 0,
          ),
          onPressed: () {
            controller.confirmAndCollect();
            Get.to(() => const OtpVerificationScreen());
          },
          child: const Text('Confirm & Collect',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
            const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.redText),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
