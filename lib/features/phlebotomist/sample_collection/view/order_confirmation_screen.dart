// order_confirmation_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/bag_context_card.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/need_route_start_view.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/not_accepted_view.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/order_instruction_card.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/order_summary_card.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/route_tracking_map.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../controller/order_confirmation_controller.dart';

class OrderConfirmationScreen extends GetView<OrderConfirmationController> {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar:  CustomAppBar(title: 'Order Details'/*,actions: [  Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Builder(
          builder: (context) => GestureDetector(
            onTapDown: (details) {
              TapPositionMenu.show(
                context: context,
                tapPosition: details.globalPosition,
                items: [
                  TapMenuItem(
                    icon: Icons.event_repeat_outlined,
                    label: 'Reschedule Sample Collection',
                    onTap: () => RescheduleSheet.show(
                      context,
                      patient: controller.assignedPatient,
                      onFetchSlots: (date) => controller.fetchAvailableSlots(date),
                      onFetchReasons: () => controller.fetchRescheduleReasons(),
                      onConfirm: (date, slot, reasonId) => controller.reschedule(
                        controller.assignedPatient,
                        newDate: date,
                        slot: slot,
                        rescheduleReasonId: reasonId,
                      ),
                    ),
                  ),
                ],
              );
            },
            child: const Padding(
              padding:  EdgeInsets.only(right: 8.0),
              child:  Icon(Icons.more_vert, color: AppColors.surface,),
            ),
          ),
        ),
      ),]*/,),
      body: Obx(() {
        if (!controller.isOrderAccepted) {
          return NotAcceptedView(patient: controller.assignedPatient);
        }
        if (controller.needsToStartRoute) {
          return NeedsRouteStartView(patient: controller.assignedPatient);
        }
        if (controller.showRouteMap.value) {
          return RouteTrackingMap(controller: controller);
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
                BagContextBanner(bagContext: controller),
                const SizedBox(height: 14),
                OrderPatientSummaryCard.fromOrder(
                  order: order,
                  initiallyExpanded: true,
                ),
                const SizedBox(height: 14),
                OrderInstructionsCard(
                  fastingRequired: order.fastingRequired,
                  fastingNote: order.fastingNote,
                  specialInstructions: {
                    for (final s in order.specialInstructions) s.instruction,
                  }.toList(),
                  initiallyExpanded: false,
                ),

              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Obx(
                    () => _ConfirmBar(
                  controller: controller,
                  enabled: controller.hasOpenBag,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  final OrderConfirmationController controller;
  final bool enabled;

  const _ConfirmBar({required this.controller, required this.enabled});

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
            backgroundColor: AppColors.secondary700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          onPressed: () {
            if (enabled) {
              controller.confirmAndCollect();
            } else {
              LiquidSnack.error(
                'You need to open a bag first for sample collection',
              );
            }
          },
          child: const Text(
            'Confirm Test Details',
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




