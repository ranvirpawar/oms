import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:http_parser/http_parser.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';


class TrfUploadService {
  final APIClient _apiClient = Get.find<APIClient>();

  /// Upload TRF photo to the server
  ///
  /// Parameters:
  /// - [filePath]: Path to the image file
  /// - [barcode]: Patient barcode
  /// - [patientName]: Patient's full name
  /// - [facilityCode]: Facility code
  /// - [creationUID]: User/Employee ID who is uploading
  ///
  /// Returns: true if upload successful, false otherwise
  Future<bool> uploadTrfPhoto({
    required String filePath,
    required String barcode,
    required String patientName,
    required String facilityCode,
    required String creationUID,
  }) async {
    try {
      final File file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final String fileName = file.path.split('/').last;
      final String ext = fileName.split('.').last.toLowerCase();

      MediaType mediaType;
      if (ext == 'jpg' || ext == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      final MultipartFile multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: mediaType,
      );

      // Photo upload → FormData
      final FormData formData = FormData.fromMap({
        'Barcode': barcode,
        'PatName': patientName,
        'FacilityCode': facilityCode,
        'CreationUID': creationUID,
        'PHOTOPATH': '',                    // string field (send empty or filename if needed)
        'Photo': multipartFile

      });

      kPrint('📤 Uploading TRF: $fileName');
      kPrint('   Barcode: $barcode');
      kPrint('   PatName: $patientName');
      kPrint('   FacilityCode: $facilityCode');
      kPrint('   CreationUID: $creationUID');

      final result = await _apiClient.post(
        AppUrls.uploadTrfImage,
        data: formData,
        isFormData: true,
      );

      kPrint('📥 Response status: ${result.statusCode}');
      kPrint('📥 Response data: ${result.data}');

      final data = result.data;

      if (data is Map) {
        if (data['status'] == 'Success') {
          kPrint('✅ Upload successful: ${data['message']}');
          return true;
        } else {
          throw Exception(data['message'] ?? 'Upload failed');
        }
      } else if (data is String) {
        kPrint('✅ Upload successful');
        return true;
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e, stackTrace) {
      kPrint('❌ Error uploading TRF photo: $e');
      kPrint('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Upload multiple TRF photos in sequence
  ///
  /// Returns: Map with success count and failed files
  Future<Map<String, dynamic>> uploadMultipleTrfPhotos({
    required List<String> filePaths,
    required String barcode,
    required String patientName,
    required String facilityCode,
    required String creationUID,
  }) async {
    int successCount = 0;
    final List<String> failedFiles = [];

    kPrint('📦 Starting batch upload of ${filePaths.length} files');

    for (int i = 0; i < filePaths.length; i++) {
      final String filePath = filePaths[i];
      kPrint(
          '📤 Uploading file ${i + 1}/${filePaths.length}: ${filePath.split('/').last}');

      try {
        final bool success = await uploadTrfPhoto(
          filePath: filePath,
          barcode: barcode,
          patientName: patientName,
          facilityCode: facilityCode,
          creationUID: creationUID,
        );

        if (success) {
          successCount++;
          kPrint('✅ File ${i + 1} uploaded successfully');
        } else {
          failedFiles.add(filePath.split('/').last);
          kPrint('❌ File ${i + 1} failed');
        }
      } catch (e) {
        failedFiles.add(filePath.split('/').last);
        kPrint('❌ File ${i + 1} failed with error: $e');
      }
    }

    kPrint('📊 Upload Summary: $successCount/${filePaths.length} successful');

    return {
      'successCount': successCount,
      'failedFiles': failedFiles,
      'totalFiles': filePaths.length,
    };
  }
}

/*class TrfUploadService {

  final Dio _dio = Dio();

  /// Upload TRF photo to the server
  ///
  /// Parameters:
  /// - [filePath]: Path to the image file
  /// - [barcode]: Patient barcode
  /// - [patientName]: Patient's full name
  /// - [facilityCode]: Facility code
  /// - [creationUID]: User/Employee ID who is uploading
  ///
  /// Returns: true if upload successful, false otherwise
  Future<bool> uploadTrfPhoto({
    required String filePath,
    required String barcode,
    required String patientName,
    required String facilityCode,
    required String creationUID,
  }) async {
    try {
      // Create file from path
      final File file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Get filename
      final String fileName = file.path.split('/').last;

      // Determine content type based on file extension
      final String ext = fileName.split('.').last.toLowerCase();
      MediaType? mediaType;

      if (ext == 'jpg' || ext == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else {
        mediaType = MediaType('image', 'jpeg'); // default
      }

      // Create multipart file
      final MultipartFile multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: mediaType,
      );

      // Prepare form data - EXACTLY as per API documentation
      final FormData formData = FormData.fromMap({
        'Barcode': barcode,
        'PatName': patientName,
        'FacilityCode': facilityCode,
        'CreationUID': creationUID,
        'PHOTOPATH': multipartFile,
      });

      // API endpoint
       final String url = AppUrls.uploadTrfImage;

      kPrint('📤 Uploading TRF: $fileName');
      kPrint('   Barcode: $barcode');
      kPrint('   PatName: $patientName');
      kPrint('   FacilityCode: $facilityCode');
      kPrint('   CreationUID: $creationUID');

      // Make POST request
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      kPrint('📥 Response status: ${response.statusCode}');
      kPrint('📥 Response data: ${response.data}');

      // Check response
      if (response.statusCode == 200) {
        final data = response.data;

        // Handle both Map and String responses
        if (data is Map) {
          if (data['status'] == 'Success') {
            kPrint('✅ Upload successful: ${data['message']}');
            return true;
          } else {
            throw Exception(data['message'] ?? 'Upload failed');
          }
        } else if (data is String) {
          // Try to parse JSON string
          try {
            final jsonData = data.contains('{') ? data : '{"status":"$data"}';
            kPrint('✅ Upload successful');
            return true;
          } catch (e) {
            throw Exception('Invalid response format');
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      kPrint('❌ DioException during TRF upload: ${e.message}');
      if (e.response != null) {
        kPrint('   Response status: ${e.response?.statusCode}');
        kPrint('   Response data: ${e.response?.data}');
      }
      return false;
    } catch (e, stackTrace) {
      kPrint('❌ Error uploading TRF photo: $e');
      kPrint('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Upload multiple TRF photos in sequence
  ///
  /// Returns: Map with success count and failed files
  Future<Map<String, dynamic>> uploadMultipleTrfPhotos({
    required List<String> filePaths,
    required String barcode,
    required String patientName,
    required String facilityCode,
    required String creationUID,
  }) async {
    int successCount = 0;
    final List<String> failedFiles = [];

    kPrint('📦 Starting batch upload of ${filePaths.length} files');

    for (int i = 0; i < filePaths.length; i++) {
      final String filePath = filePaths[i];
      kPrint('📤 Uploading file ${i + 1}/${filePaths.length}: ${filePath.split('/').last}');

      try {
        final bool success = await uploadTrfPhoto(
          filePath: filePath,
          barcode: barcode,
          patientName: patientName,
          facilityCode: facilityCode,
          creationUID: creationUID,
        );

        if (success) {
          successCount++;
          kPrint('✅ File ${i + 1} uploaded successfully');
        } else {
          failedFiles.add(filePath.split('/').last);
          kPrint('❌ File ${i + 1} failed');
        }
      } catch (e) {
        failedFiles.add(filePath.split('/').last);
        kPrint('❌ File ${i + 1} failed with error: $e');
      }
    }

    kPrint('📊 Upload Summary: $successCount/${ filePaths.length} successful');

    return {
      'successCount': successCount,
      'failedFiles': failedFiles,
      'totalFiles': filePaths.length,
    };
  }
}*/