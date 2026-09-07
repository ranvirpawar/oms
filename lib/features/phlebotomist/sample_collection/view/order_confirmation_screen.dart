// order_confirmation_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../../patient_registration/bag_status_dashboard/view/scan_bag_page.dart';
import '../../patient_queue/model/patient_queue_model.dart';
import '../controller/sample_collection_controller.dart';
import '../model/sample_collection_models.dart';
import 'widgets/active_bag_card.dart';
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
        // Accepted, but route hasn't started — don't wait on orderDetails,
        // there's nothing loaded yet.
        if (controller.needsToStartRoute) {
          return _NeedsRouteStartView(patient: controller.assignedPatient);
        }

        // En route — full-screen live tile map with the destination pin,
        // current GPS position and the "Arrived at Location" action.
        if (controller.showRouteMap.value) {
          return _RouteTrackingMap(controller: controller);
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
                _BagContextBanner(controller: controller),
                const SizedBox(height: 14),
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

/// Compact banner showing which open bag this collection is being tagged
/// to, or a call-to-action when no bag is open.
class _BagContextBanner extends StatelessWidget {
  final SampleCollectionController controller;

  const _BagContextBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bag = controller.bagController;
      // Hide while the very first session fetch is still in flight.
      if (bag.isLoading.value && !bag.hasBags) return const SizedBox.shrink();

      if (!controller.hasOpenBag) {
        // Closed assigned bags can be reopened — don't force the phlebo
        // through the new-bag scan flow when their own bag just needs
        // reopening.
        final closedSessions = bag.allSessions.where((s) => !s.isOpen).toList();
        final message = closedSessions.isEmpty
            ? 'No open bag — open one so samples can be tagged to it.'
            : closedSessions.length == 1
            ? 'Bag ${closedSessions.first.bagcode} is closed — reopen it '
                  'so samples can be tagged to it.'
            : 'No open bag — reopen one of your closed bags to continue.';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.amberLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.amberBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.amberText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              if (closedSessions.isNotEmpty)
                TextButton(
                  onPressed: () {
                    if (closedSessions.length == 1) {
                      confirmOpenBag(context, closedSessions.first);
                    } else {
                      showBagPicker(context, controller);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary800,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Reopen',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Get.to(() => const ScanBagPage()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary800,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  closedSessions.isEmpty ? 'Open' : 'New',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final ratio = controller.bagFillRatio;
      final color = ratio >= 0.9
          ? AppColors.redText
          : (ratio >= 0.6 ? AppColors.amberText : AppColors.greenText);
      final pct = (ratio * 100).round().clamp(0, 100).toInt();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.emerald50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.emerald200),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collecting into ${controller.activeBagcode.isEmpty ? 'Bag #${controller.activeBagId}' : controller.activeBagcode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    controller.bagCapacity > 0
                        ? '${controller.bagUsed} of ${controller.bagCapacity} slots used'
                        : 'Open session',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (controller.bagCapacity > 0) ...[
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      );
    });
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

class _RouteTrackingMap extends StatefulWidget {
  final SampleCollectionController controller;

  const _RouteTrackingMap({required this.controller});

  @override
  State<_RouteTrackingMap> createState() => _RouteTrackingMapState();
}

class _RouteTrackingMapState extends State<_RouteTrackingMap>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _hasFramedOnce = false;

  List<LatLng>? _routePoints;
  LatLng? _routeFetchedForDestination;
  bool _isFetchingRoute = false;

  // --- Smooth marker animation ---
  late final AnimationController _markerAnimController;
  LatLng? _animFrom;
  LatLng? _animTo;
  LatLng? _displayedCurrent;

  // --- Follow-me camera ---
  bool _followMode = true;
  double _currentZoom = 15;

  SampleCollectionController get controller => widget.controller;

  LatLng? get _destination {
    final lat = controller.destinationLat;
    final lng = controller.destinationLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _rawCurrent {
    final pos = controller.currentPosition.value;
    if (pos == null) return null;
    return LatLng(pos.latitude, pos.longitude);
  }

  @override
  void initState() {
    super.initState();
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onMarkerTick);

    // Fires every time the GPS gives a new fix.
    ever<Position?>(controller.currentPosition, (pos) {
      if (pos == null) return;
      _onNewFix(LatLng(pos.latitude, pos.longitude));
    });
  }

  @override
  void dispose() {
    _markerAnimController.dispose();
    super.dispose();
  }

  void _onNewFix(LatLng next) {
    final from = _displayedCurrent ?? next;
    _animFrom = from;
    _animTo = next;
    _markerAnimController
      ..reset()
      ..forward();

    if (_followMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(next, _currentZoom);
      });
    }
  }

  void _onMarkerTick() {
    final from = _animFrom;
    final to = _animTo;
    if (from == null || to == null) return;
    final t = Curves.easeInOut.transform(_markerAnimController.value);
    setState(() {
      _displayedCurrent = LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
    });
  }

  void _fitToPoints(List<LatLng> points) {
    if (points.length < 2) return;
    final bounds = LatLngBounds.fromPoints(points);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(60, 100, 60, 220),
        ),
      );
    });
  }

  Future<List<LatLng>?> _fetchRoute(LatLng origin, LatLng dest) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${dest.longitude},${dest.latitude}'
      '?overview=full&geometries=polyline',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      return _decodePolyline(routes.first['geometry'] as String);
    } catch (_) {
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  void _maybeFetchRoute(LatLng current, LatLng destination) {
    if (_isFetchingRoute) return;
    if (_routePoints != null && _routeFetchedForDestination == destination) {
      return;
    }
    _isFetchingRoute = true;
    _fetchRoute(current, destination).then((points) {
      if (!mounted) return;
      setState(() {
        _isFetchingRoute = false;
        if (points != null && points.isNotEmpty) {
          _routePoints = points;
          _routeFetchedForDestination = destination;
        }
      });
      if (points != null && points.isNotEmpty && !_followMode) {
        _fitToPoints(points);
      }
    });
  }

  Future<void> _launchDirections(LatLng dest) async {
    final uri = Platform.isIOS
        ? Uri.parse(
            'https://maps.apple.com/?daddr=${dest.latitude},${dest.longitude}',
          )
        : Uri.parse(
            'google.navigation:q=${dest.latitude},${dest.longitude}&mode=d',
          );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rawCurrent = _rawCurrent;
      final destination = _destination;
      final current = _displayedCurrent ?? rawCurrent;

      if (rawCurrent != null && destination != null) {
        if (!_hasFramedOnce) {
          _hasFramedOnce = true;
          _displayedCurrent ??= rawCurrent;
          _fitToPoints([rawCurrent, destination]);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeFetchRoute(rawCurrent, destination);
        });
      }

      final routeLine =
          _routePoints ??
          (current != null && destination != null
              ? [current, destination]
              : null);

      return Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  current ?? destination ?? const LatLng(19.8762, 75.3433),
              initialZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                _currentZoom = position.zoom;
                // If the user drags the map themselves, drop out of
                // follow mode so we don't fight their gesture.
                if (hasGesture && _followMode) {
                  setState(() => _followMode = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lifenity_health.oms',
              ),
              if (routeLine != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeLine,
                      strokeWidth: _routePoints != null ? 4.5 : 3.5,
                      color: AppColors.blue,
                      pattern: _routePoints != null
                          ? const StrokePattern.solid()
                          : const StrokePattern.dotted(),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (destination != null)
                    Marker(
                      point: destination,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.redText,
                        size: 40,
                      ),
                    ),
                  if (current != null)
                    Marker(
                      point: current,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blue,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _StatusPill(
              controller: controller,
              // isRouting: _isFetchingRoute && _routePoints == null, //todo
            ),
          ),

          // Recenter button — appears once the user has panned away
          // from follow mode.
          if (!_followMode)
            Positioned(
              right: 16,
              bottom: 190,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: AppColors.bgCard,
                onPressed: () {
                  setState(() => _followMode = true);
                  final target = _displayedCurrent ?? _rawCurrent;
                  if (target != null) {
                    _mapController.move(target, _currentZoom);
                  }
                },
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.blue,
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _RouteBottomSheet(
              controller: controller,
              onDirections: destination != null
                  ? () => _launchDirections(destination)
                  : null,
            ),
          ),
        ],
      );
    });
  }
}
/*class _RouteTrackingMapState extends State<_RouteTrackingMap> {
  final MapController _mapController = MapController();
  bool _hasFramedOnce = false;

  SampleCollectionController get controller => widget.controller;

  LatLng? get _destination {
    final lat = controller.destinationLat;
    final lng = controller.destinationLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _current {
    final pos = controller.currentPosition.value;
    if (pos == null) return null;
    return LatLng(pos.latitude, pos.longitude);
  }

  void _fitToRoute(LatLng current, LatLng destination) {
    final bounds = LatLngBounds.fromPoints([current, destination]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(60, 100, 60, 220),
        ),
      );
    });
  }

  Future<void> _launchDirections(LatLng dest) async {
    final uri = Platform.isIOS
        ? Uri.parse(
            'https://maps.apple.com/?daddr=${dest.latitude},${dest.longitude}')
        : Uri.parse(
            'google.navigation:q=${dest.latitude},${dest.longitude}&mode=d');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = _current;
      final destination = _destination;

      // Frame both points once, on the first GPS fix.
      if (current != null && destination != null && !_hasFramedOnce) {
        _hasFramedOnce = true;
        _fitToRoute(current, destination);
      }

      return Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  current ?? destination ?? const LatLng(19.8762, 75.3433),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lifenity_health.oms',
              ),
              if (current != null && destination != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [current, destination],
                      strokeWidth: 3.5,
                      color: AppColors.blue,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (destination != null)
                    Marker(
                      point: destination,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.redText,
                        size: 40,
                      ),
                    ),
                  if (current != null)
                    Marker(
                      point: current,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blue,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Status pill.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _StatusPill(controller: controller),
          ),

          // Bottom action sheet — distance, progress, Directions, Arrived.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _RouteBottomSheet(
              controller: controller,
              onDirections: destination != null
                  ? () => _launchDirections(destination)
                  : null,
            ),
          ),
        ],
      );
    });
  }
}*/

/// Floating "On the way to {patient name}" pill over the map.
class _StatusPill extends StatelessWidget {
  final SampleCollectionController controller;

  const _StatusPill({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_filled_rounded,
            color: AppColors.blue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'On the way to ${controller.assignedPatient.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed bottom sheet over the map — distance readout, route progress bar
/// and the Directions / Arrived actions (reachable one-handed).
class _RouteBottomSheet extends StatelessWidget {
  final SampleCollectionController controller;
  final VoidCallback? onDirections;

  const _RouteBottomSheet({required this.controller, this.onDirections});

  String _distanceLabel(double? meters) {
    if (meters == null) return 'Locating…';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km away';
    return '${meters.toStringAsFixed(0)} m away';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        final distance = controller.distanceToPatientMeters;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _distanceLabel(distance),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    controller.assignedPatient.address ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: controller.routeProgress,
                minHeight: 5,
                backgroundColor: AppColors.grayLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent700),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: controller.isMarkingArrived.value
                        ? null
                        : controller.markArrived,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: controller.isMarkingArrived.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Arrived at Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

/// Shown when the order is accepted but the phlebotomist hasn't started
/// the route yet — nothing has been fetched, so this is purely informational.
class _NeedsRouteStartView extends StatelessWidget {
  final AssignedPatient patient;

  const _NeedsRouteStartView({required this.patient});

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
          child: Row(
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
              Icon(Icons.route_outlined, size: 18, color: AppColors.amberText),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You need to start the route and mark yourself as '
                  'arrived at the collection location before you can '
                  'collect the sample.',
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
