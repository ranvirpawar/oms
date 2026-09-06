import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';

import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/facility_center_name_model.dart';
import '../model/facility_center_type_model.dart';
import '../model/visit_request_model.dart';
import '../services/visit_service.dart';

import 'add_visit_state.dart';

class AddVisitNotifier extends StateNotifier<AddVisitState> {
  final VisitService _visitService;
  final String _userId;
  StreamSubscription<Position>? _positionSub;
  AddVisitNotifier(
      this._visitService,
      this._userId,
      ) : super(
    AddVisitState(),
  ) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    state = state.copyWith(isFetchingLocation: true, clearError: true);
    try {
      await _ensurePermissions();

      // 1. Instant, non-blocking: show a last-known fix immediately if we have one,
      //    so the UI isn't blank while we wait for a fresh reading.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        state = state.copyWith(
          latitude: lastKnown.latitude.toString(),
          longitude: lastKnown.longitude.toString(),
        );
        _recalculateDistance();
      }

      // 2. Try for a fresh, high-accuracy fix — but degrade gracefully instead
      //    of throwing the user into an error screen.
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, // 'best' waits longer for marginal gains
          ),
        ).timeout(const Duration(seconds: 20));
      } on TimeoutException {
        // Fresh fix didn't arrive in time — fall back to whatever the position
        // stream gives us first, with a shorter grace period.
        try {
          position = await Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).first.timeout(const Duration(seconds: 10));
        } on TimeoutException {
          position = null; // give up on a fresh fix, keep last-known if we had one
        }
      }

      if (position != null) {
        state = state.copyWith(
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
        );
        _recalculateDistance();
      } else if (lastKnown == null) {
        // No fresh fix AND no last-known fix at all — genuinely can't locate.
        throw Exception(
          'Could not get a GPS fix. Please move near a window/outdoors and tap refresh.',
        );
      }
      // else: we're just running on the last-known fix silently — not a hard error.

      state = state.copyWith(isFetchingLocation: false);
      _startLiveTracking();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isFetchingLocation: false);
    }
  }
  Future<void> _ensurePermissions() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
  }
  void _startLiveTracking() {
    _positionSub?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5, // only emit updates after moving 5 meters — tune this
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position position) {
      state = state.copyWith(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
      );
      _recalculateDistance();
    }, onError: (e) {
      state = state.copyWith(error: 'Location tracking error: $e');
    });
  }

  Future<void> refreshLocation() async => _initLocation();
  void updateDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void updateTime(TimeOfDay time) {
    state = state.copyWith(selectedTime: time);
  }

  // Updated to work with FacilityCenterType and clear selected facility
  void updateFacilityType(FacilityCenterType? facilityType) {
    state = state.copyWith(
      selectedFacilityType: facilityType,
      clearFacility: true,
      clearDistance: true,
    );
  }

  // Updated to work with FacilityCenterName
  void updateSelectedFacility(FacilityCenterName? facility) {
    kPrint('Updating selected facility to: ${facility?.centerLabName ?? 'null'}');
    state = state.copyWith(selectedFacility: facility);
    // _recalculateDistance();
    refreshLocation();
  }

  void updateDrFirstName(String name) {
    state = state.copyWith(drFirstName: name);
  }

  void updateDrMidName(String name) {
    state = state.copyWith(drMidName: name);
  }

  void updateDrLastName(String name) {
    state = state.copyWith(drLastName: name);
  }

  void updateMobileNo(String mobile) {
    state = state.copyWith(mobileNo: mobile);
  }

  void updateRemark(String remark) {
    state = state.copyWith(remark: remark);
  }

  void updatePhoto(File? photo) {
    state = state.copyWith(selectedPhoto: photo);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void removePhoto() {
    kPrint('Removing photo');
    state = state.copyWith(clearPhoto: true);
  }
  void _recalculateDistance() {
    final facility = state.selectedFacility;
    final lat = state.latitude;
    final lng = state.longitude;

    if (facility?.latitude == null ||
        facility?.longitude == null ||
        lat == null ||
        lng == null) {
      state = state.copyWith(clearDistance: true);
      return;
    }

    final distance = Geolocator.distanceBetween(
      double.parse(lat),
      double.parse(lng),
      facility!.latitude!,
      facility.longitude!,
    );

    state = state.copyWith(distanceInMeters: distance);
    kPrint('Distance to facility: ${distance.toStringAsFixed(1)}m '
        '(within radius: ${state.isWithinRadius})');
    state = state.copyWith(distance: formatDistance(distance));
  }
  String formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) {
      return 'Locating you...';
    }

    if (distanceInMeters < 1000) {
      return 'You are ${distanceInMeters.round()} m away';
    }

    final km = distanceInMeters / 1000;
    final distance =
    km >= 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(2);

    return 'You are $distance km away';
  }
  Future<Position> _determinePosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  Future<void> submitVisit() async {
    if (!_validateForm()) return;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final request = VisitRequestModel(
        centerId: state.selectedFacility!.centerId.toString(),
        drFirstName: state.drFirstName,
        drMidName: state.drMidName,
        drLastName: state.drLastName,
        mobileNo: state.mobileNo,
        photoPath: '',
        remark: state.remark,
        latitude: state.latitude ?? '',
        longitude: state.longitude ?? '',
        userId: _userId,
      );

      final response = await _visitService.submitVisit(request);

      if (response.status == 'Sucess') {
        if (state.selectedPhoto != null) {
          final surveyId = response.output.first.surveyId;
          final photoResponse = await _visitService.uploadPhoto(
            userId: _userId,
            surveyId: surveyId,
            imageFile: state.selectedPhoto!,
          );
          if (photoResponse['status'] != 'Success') {
            throw Exception('Photo upload failed: ${photoResponse['message']}');
          }
        }
        clearForm();
        RouteManager.redirectToHomeDashboard();
        SnackBarService.to.showMessage(message: 'Visit Added Successfully');
      } else {
        throw Exception('Visit submission failed: ${response.status}');
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Something went wrong please retry!',
      );
    }
  }
  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
  void clearForm() {
    _positionSub?.cancel();
    state = AddVisitState();
    _initLocation();
  }

  bool _validateForm() {
    if (state.selectedFacility == null) {
      state = state.copyWith(error: 'Please select a facility');
      return false;
    }
    if (state.drFirstName.isEmpty) {
      state = state.copyWith(error: 'Please enter doctor first name');
      return false;
    }
    if (state.mobileNo.isEmpty || state.mobileNo.length != 10) {
      state = state.copyWith(error: 'Please enter valid mobile number');
      return false;
    }
    if (state.remark.isEmpty) {
      state = state.copyWith(error: 'Please enter a remark');
      return false;
    }
    if (state.selectedPhoto == null) {
      state = state.copyWith(error: 'Please select a photo');
      return false;
    }
    /*// NEW: hard gate on geofence
    if (!state.isWithinRadius) {
      state = state.copyWith(
        error: state.distanceInMeters == null
            ? 'Unable to verify your location. Please enable GPS and try again.'
            : 'You must be within 50m of the facility to submit. '
            'You are currently ${state.distanceInMeters!.toStringAsFixed(0)}m away.',
      );
      return false;
    }*/
    return true;
  } 
}
