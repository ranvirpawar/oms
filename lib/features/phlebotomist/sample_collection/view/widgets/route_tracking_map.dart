import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import 'order_summary_card.dart';

class RouteTrackingMap extends StatefulWidget {
  final SampleCollectionController controller;

  const RouteTrackingMap({super.key, required this.controller});

  @override
  State<RouteTrackingMap> createState() => RouteTrackingMapState();
}

class RouteTrackingMapState extends State<RouteTrackingMap> {
  final MapController _mapController = MapController();
  bool _hasFramedOnce = false;

  SampleCollectionController get controller => widget.controller;

  LatLng? get _destination {
    final lat = controller.destinationLat,
        lng = controller.destinationLng;
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
          'https://www.google.com/maps/dir/?api=1&destination=${dest
              .latitude},${dest.longitude}',
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
                userAgentPackageName: 'com.lifenity.connect',
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

          // Floating, collapsible patient/test summary — replaces the old
          // bare "On the way to X" pill. Collapsed it's the same compact
          // pill (plus a test-count chip); tapping it expands in place to
          // show instructions and the full test list without leaving the
          // map or covering the bottom action sheet.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: OrderPatientSummaryCard.fromAssignedPatient(
                patient: controller.assignedPatient,
                floating: true,
              ),
            ),
          ),

          // Bottom action sheet
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
                Text(
                  controller.assignedPatient.address ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
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