import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';


class DeviceInfoService {
  // Singleton pattern
  static final DeviceInfoService _instance = DeviceInfoService._internal();

  factory DeviceInfoService() => _instance;

  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final AndroidId _androidId = const AndroidId();

  /// Fetches device information including:
  /// - IMEI (device ID approximation as IMEI isn't accessible directly)
  /// - App version
  /// - Device model name
  /// - Device type (Android/iOS)
  /// - Device OS version
  Future<Map<String, String>> getDeviceInfo() async {
    final Map<String, String> deviceData = {
      'imeiNo': await _getDeviceId(),
      'appVersion': await _getAppVersion(),
      'deviceModelName': await _getDeviceModel(),
      'deviceType': _getDeviceType(),
      'deviceVersionName': await _getDeviceOSVersion(),
    };

    // Print device data for debugging
    print('Device Data: $deviceData');

    return deviceData;
  }

  /// Gets a device identifier
  /// Note: This is NOT an actual IMEI number as direct access to IMEI is restricted
  /// Returns a device identifier that can be used for tracking the device
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        // Android ID is a device identifier
        // final deviceId = androidInfo.id; // Deprecated, use androidId
        final fingerprint = androidInfo.fingerprint;

        print(fingerprint);

        final deviceId = await _getAndroidIdOnly();

        /*return deviceId;*/
        return '$deviceId-$fingerprint';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        // identifierForVendor is the closest equivalent on iOS
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      print('Error getting device ID: $e');
    }
    return 'unknown';
  }

  /// Gets the app version from package info
  Future<String> _getAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
      // return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      print('Error getting app version: $e');
      return 'unknown';
    }
  }

  /// Gets the device model name
  Future<String> _getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.model;
      }
    } catch (e) {
      print('Error getting device model: $e');
    }
    return 'unknown';
  }

  /// Returns the device type (Android/iOS)
  String _getDeviceType() {
    return Platform.isAndroid ? 'ANDROID' : 'iOS';
  }

  /// Gets the device OS version
  Future<String> _getDeviceOSVersion() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      print('Error getting OS version: $e');
    }
    return 'unknown';
  }

  Future<String> _getAndroidIdOnly() async {
    try {
      if (Platform.isAndroid) {
        final String? androidId = await _androidId.getId();
        print('Android Id : $androidId');
        return androidId ?? 'unknown';
      }
    } catch (e) {
      print('Error getting Android ID: $e');
    }
    return 'unknown';
  }
}