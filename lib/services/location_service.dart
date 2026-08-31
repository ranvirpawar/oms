// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get location as strings
  Future<Map<String, String>> getLocationStrings() async {
    final position = await getCurrentLocation();
    if (position != null) {
      return {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      };
    }
    return {
      'latitude': '0.0',
      'longitude': '0.0',
    };
  }
}