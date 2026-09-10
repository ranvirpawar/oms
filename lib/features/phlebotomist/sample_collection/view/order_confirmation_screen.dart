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
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/order_summary_card.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/route_tracking_map.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../../patient_registration/bag_status_dashboard/view/scan_bag_page.dart';
import '../../patient_queue/model/patient_queue_model.dart';
import '../controller/sample_collection_controller.dart';
import '../model/sample_collection_models.dart';
import 'widgets/active_bag_card.dart';
import 'widgets/otp_verification_screen.dart';
// order_confirmation_screen.dart

class OrderConfirmationScreen extends GetView<SampleCollectionController> {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: const CustomAppBar(title: 'Order Details'),
      body: Obx(() {
        if (!controller.isOrderAccepted) {
          return NotAcceptedView(patient: controller.assignedPatient);
        }
        // Accepted, but route hasn't started — don't wait on orderDetails,
        // there's nothing loaded yet.
        if (controller.needsToStartRoute) {
          return NeedsRouteStartView(patient: controller.assignedPatient);
        }

        // En route — full-screen live tile map with the destination pin,
        // current GPS position, a floating expandable patient/test summary,
        // and the "Arrived at Location" action.
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
                // Bag context: which open bag this collection will be
                // tagged to (or a prompt to open one).
                BagContextBanner(controller: controller),
                const SizedBox(height: 14),

                OrderPatientSummaryCard.fromOrder(
                  order: order,
                  initiallyExpanded: true,
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Obx(
                    () =>
                    _ConfirmBar(
                      controller: controller,
                      enabled:
                      controller.hasOpenBag, // pass this through to the button
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
  final SampleCollectionController controller;
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
            backgroundColor: AppColors.accent700,
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
          'Confirm & Collect',
          style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),)
    ,
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





