import 'dart:io';

import 'package:flutter/material.dart';

import '../model/facility_center_name_model.dart';
import '../model/facility_center_type_model.dart';

// STATE CLASS - add_visit_state.dart

class AddVisitState {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final FacilityCenterType? selectedFacilityType;
  final FacilityCenterName? selectedFacility;
  final String drFirstName;
  final String drMidName;
  final String drLastName;
  final String mobileNo;
  final String remark;
  final File? selectedPhoto;
  final String? latitude;
  final String? longitude;
  final bool isSubmitting;
  final String? error;

  // NEW
  final double? distanceInMeters;
  final String? distance;
  final bool isFetchingLocation;
  static const double allowedRadiusMeters = 50.0;

  AddVisitState({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    this.selectedFacilityType,
    this.selectedFacility,
    this.drFirstName = '',
    this.drMidName = '',
    this.drLastName = '',
    this.mobileNo = '',
    this.remark = '',
    this.selectedPhoto,
    this.latitude,
    this.longitude,
    this.isSubmitting = false,
    this.error,
    this.distanceInMeters,
    this.distance ,
    this.isFetchingLocation = false,
  })  : selectedDate = selectedDate ?? DateTime.now(),
        selectedTime = selectedTime ?? TimeOfDay.now();

  bool get isWithinRadius =>
      distanceInMeters != null && distanceInMeters! <= allowedRadiusMeters;

  AddVisitState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    FacilityCenterType? selectedFacilityType,
    FacilityCenterName? selectedFacility,
    String? drFirstName,
    String? drMidName,
    String? drLastName,
    String? mobileNo,
    String? remark,
    File? selectedPhoto,
    String? latitude,
    String? longitude,
    bool? isSubmitting,
    String? error,
    double? distanceInMeters,
    String? distance,
    bool? isFetchingLocation,
    bool clearError = false,
    bool clearFacility = false,
    bool clearPhoto = false,
    bool clearDistance = false,
  }) {
    return AddVisitState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedFacilityType: selectedFacilityType ?? this.selectedFacilityType,
      selectedFacility: clearFacility ? null : (selectedFacility ?? this.selectedFacility),
      drFirstName: drFirstName ?? this.drFirstName,
      drMidName: drMidName ?? this.drMidName,
      drLastName: drLastName ?? this.drLastName,
      mobileNo: mobileNo ?? this.mobileNo,
      remark: remark ?? this.remark,
      selectedPhoto: clearPhoto ? null : (selectedPhoto ?? this.selectedPhoto),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      distanceInMeters: clearDistance ? null : (distanceInMeters ?? this.distanceInMeters),
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      distance: distance ?? this.distance,
    );
  }

}