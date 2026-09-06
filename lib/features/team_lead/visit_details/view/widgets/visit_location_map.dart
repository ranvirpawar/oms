import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../theme/app_colors.dart';

class VisitLocationMapWidget extends StatefulWidget {
  final double userLat;
  final double userLng;
  final double facilityLat;
  final double facilityLng;
  final double? distanceInMeters;
  final bool isWithinRadius;
  final VoidCallback onRefreshLocation;
  final bool isRefreshing;
  final String distance;

  const VisitLocationMapWidget({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.facilityLat,
    required this.facilityLng,
    required this.distanceInMeters,
    required this.isWithinRadius,
    required this.onRefreshLocation,
    required this.distance,
    this.isRefreshing = false,
  });

  @override
  State<VisitLocationMapWidget> createState() => _VisitLocationMapWidgetState();
}

class _VisitLocationMapWidgetState extends State<VisitLocationMapWidget> {
  GoogleMapController? _mapController;

  BitmapDescriptor? _facilityIcon;
  BitmapDescriptor? _userIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
  }

  // Renders custom Flutter widgets (hospital pin, user dot) into
  // BitmapDescriptors, since GoogleMap markers only accept bitmaps —
  // not arbitrary widgets like flutter_map's Marker(child: ...) did.
  // Target ON-SCREEN size in logical pixels — this is what actually controls
  // how big the marker looks on the map. Render slightly larger than this
  // for crispness on high-DPI screens, then tell BitmapDescriptor the real
  // display size via width/height so it isn't drawn at raw pixel size
  // (that mismatch — rendering at devicePixelRatio but not telling the
  // descriptor the intended logical size — is why the old markers looked huge).
  static const double _facilityMarkerSize = 30;
  static const double _userMarkerSize = 18;

  Future<void> _loadCustomIcons() async {
    final facilityBytes = await _widgetToPngBytes(
      const Icon(Icons.local_hospital, color: AppColors.primary, size: 20),
      size: _facilityMarkerSize,
    );
    final userBytes = await _widgetToPngBytes(
      _StaticUserDot(isWithinRadius: widget.isWithinRadius),
      size: _userMarkerSize,
    );

    if (!mounted) return;
    setState(() {
      _facilityIcon = BitmapDescriptor.bytes(
        facilityBytes,
        width: _facilityMarkerSize,
        height: _facilityMarkerSize,
      );
      _userIcon = BitmapDescriptor.bytes(
        userBytes,
        width: _userMarkerSize,
        height: _userMarkerSize,
      );
    });
  }

  Future<Uint8List> _widgetToPngBytes(Widget widget, {required double size}) async {
    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(Size(size, size)),
        devicePixelRatio: WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio,
      ),
    );
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(textDirection: TextDirection.ltr, child: widget),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(
      pixelRatio: WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _fitBounds() {
    if (_mapController == null) return;
    final bounds = _boundsFor([
      LatLng(widget.userLat, widget.userLng),
      LatLng(widget.facilityLat, widget.facilityLng),
    ]);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void didUpdateWidget(covariant VisitLocationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final facilityChanged = oldWidget.facilityLat != widget.facilityLat ||
        oldWidget.facilityLng != widget.facilityLng;

    if (widget.isWithinRadius != oldWidget.isWithinRadius) {
      // regenerate the user dot icon with the new color
      _loadCustomIcons();
    }

    if (facilityChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
      return;
    }

    // User moved — only re-fit if they've walked outside the current visible region
    _mapController?.getVisibleRegion().then((bounds) {
      final userPoint = LatLng(widget.userLat, widget.userLng);
      if (!bounds.contains(userPoint)) {
        _fitBounds();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userPoint = LatLng(widget.userLat, widget.userLng);
    final facilityPoint = LatLng(widget.facilityLat, widget.facilityLng);
    final bounds = _boundsFor([userPoint, facilityPoint]);
    final center = LatLng(
      (userPoint.latitude + facilityPoint.latitude) / 2,
      (userPoint.longitude + facilityPoint.longitude) / 2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          SizedBox(
            height: 260,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 16),
              onMapCreated: (controller) {
                _mapController = controller;
                // fit after first frame so the map has its final size
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
                });
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              // Without this, a parent Column/ListView/PageView (or any
              // ancestor GestureDetector) can win the gesture arena for
              // drag and pinch-scale, leaving only taps/double-taps working
              // on the map — which matches exactly what you're seeing.
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('facility_radius'),
                  center: facilityPoint,
                  radius: 50, // meters
                  fillColor: (widget.isWithinRadius ? Colors.green : Colors.orange)
                      .withOpacity(0.15),
                  strokeColor: widget.isWithinRadius ? Colors.green : Colors.orange,
                  strokeWidth: 2,
                ),
              },
              markers: {
                Marker(
                  markerId: const MarkerId('facility'),
                  position: facilityPoint,
                  icon: _facilityIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  anchor: const Offset(0.5, 0.5),
                ),
                Marker(
                  markerId: const MarkerId('user'),
                  position: userPoint,
                  icon: _userIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        widget.isWithinRadius
                            ? BitmapDescriptor.hueBlue
                            : BitmapDescriptor.hueOrange,
                      ),
                  anchor: const Offset(0.5, 0.5),
                ),
              },
            ),
          ),

          // Top floating distance pill
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _DistancePill(
              distance: widget.distance,
              distanceInMeters: widget.distanceInMeters,
              isWithinRadius: widget.isWithinRadius,
            ),
          ),

          // Refresh location FAB
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'refreshLocationFab',
              backgroundColor: Colors.white,
              onPressed: widget.isRefreshing ? null : widget.onRefreshLocation,
              child: widget.isRefreshing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Padding(
                padding: EdgeInsets.all(2.0),
                child: Column(
                  children: [
                    Icon(Icons.my_location, color: AppColors.primary),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOTE on the pulsing animation:
// Google Maps markers are static bitmaps rendered by the native map SDK —
// they can't host a live AnimatedBuilder like flutter_map's widget markers
// could. This _StaticUserDot is a single-frame version (no pulse) used to
// generate the marker icon.
//
// If you want the animated pulse to keep working, you have two options:
//   1. Overlay a separate Flutter widget (Positioned + AnimatedBuilder) on
//      top of the GoogleMap using GoogleMapController.getScreenCoordinate()
//      to convert the LatLng to pixel offsets on every camera move, and
//      re-position the overlay widget each frame/tick. More faithful, more
//      code, needs a Timer or camera-idle listener to reposition on pan/zoom.
//   2. Periodically regenerate the marker BitmapDescriptor on a Timer.periodic
//      (e.g. every 100ms) with a different scale/opacity, similar to
//      _loadCustomIcons() above. Simple but noticeably heavier — regenerating
//      and re-uploading a bitmap marker repeatedly is not cheap.
// Most apps ship with a static (non-pulsing) "you are here" dot on Google
// Maps for exactly this reason.
// ---------------------------------------------------------------------------
class _StaticUserDot extends StatelessWidget {
  final bool isWithinRadius;

  const _StaticUserDot({required this.isWithinRadius});

  @override
  Widget build(BuildContext context) {
    final color = isWithinRadius ? Colors.blue : Colors.deepOrange;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _DistancePill extends StatelessWidget {
  final double? distanceInMeters;
  final bool isWithinRadius;
  final String distance;

  const _DistancePill({
    required this.distanceInMeters,
    required this.isWithinRadius,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWithinRadius ? Colors.green : Colors.deepOrange;
    final label = distance.isNotEmpty ? distance : 'Locating you...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isWithinRadius ? Icons.check_circle : Icons.location_on,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}