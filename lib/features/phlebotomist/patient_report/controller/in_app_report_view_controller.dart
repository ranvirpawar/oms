import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_report/model/patiet_report_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/snackbar_service.dart';
import '../view/widget/pdf_failure_widget.dart';

class ReportPdfViewerController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasStoragePermission = false.obs;
  final RxnString localPath = RxnString();
  final RxInt currentPage = 0.obs;
  final RxInt totalPages = 0.obs;
  PDFViewController? pdfController;

  late String barcode;
  late String downloadUrl;
  late PatientReportData? report;
  var fileName = 'report.pdf';

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments ?? {};
    barcode = arguments['barcode'] ?? '';
    downloadUrl = arguments['downloadUrl'] ?? '';
    report = arguments['report'] as PatientReportData?;

    debugPrint('Controller initialized with:');
    debugPrint('Barcode: $barcode');
    debugPrint('DownloadUrl: $downloadUrl');

    _checkInitialPermissions();
    if (downloadUrl.isNotEmpty) {
      loadPdf();
    }
  }

  void showCuteAlertDialog(String downloadUrl) {
    Get.dialog(
      PdfFailureWidget(downloadUrl: downloadUrl),
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 400),
      transitionCurve: Curves.easeInOutCubic,
    );
  }

  Future<void> openInBrowser() async {
    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      SnackBarService.to.showMessage(message: 'Cannot open report URL');
    }
  }

  Future<void> loadPdf() async {
    if (!isValidUrl(downloadUrl)) {
      errorMessage.value = 'Invalid report URL';
      debugPrint('Error: $errorMessage.value');
      isLoading.value = false;
      return;
    }

    // For viewing PDFs, we'll use app-specific storage which doesn't require permissions
    try {
      isLoading.value = true;
      final tempDir = await getTemporaryDirectory();
      final fileName = '${barcode}_report.pdf';
      final file = File('${tempDir.path}/$fileName');

      // AVOIDING CACHE CHECK FOR ALWAYS FRESH DOWNLOAD
      /*
      debugPrint('Checking if file exists at: ${file.path}');
     if (await file.exists()) {
        debugPrint('File exists, using cached PDF');
        localPath.value = file.path;
        isLoading.value = false;
        return;
      }*/

      debugPrint('Downloading PDF from: $downloadUrl');
      final dio = Dio();
      await dio.download(
        downloadUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
            debugPrint(
                'Download progress: ${(downloadProgress.value * 100).toStringAsFixed(2)}%');
          }
        },
      );

      debugPrint('Download completed, file saved at: ${file.path}');
      if (await file.exists()) {
        localPath.value = file.path;
      } else {
        errorMessage.value = 'Downloaded file not found';
        debugPrint('Error: $errorMessage.value');
        localPath.value = null;
      }
    } catch (e, stackTrace) {
      errorMessage.value = 'Failed to load PDF: $e';
      debugPrint('Error loading PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      showCuteAlertDialog(downloadUrl);
      localPath.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      debugPrint('Invalid URL: $url');
      return false;
    }
  }

  Future<void> downloadPdf() async {
    if (isDownloading.value) return;

    if (downloadUrl.isEmpty || !isValidUrl(downloadUrl)) {
      SnackBarService.to.showMessage(message: 'Invalid or missing report URL');
      return;
    }

    HapticFeedback.vibrate();

    // Check if we need storage permission for downloads to external storage
    if (!hasStoragePermission.value) {
      final granted = await _requestStoragePermission();
      if (!granted) {
        // Fallback: download to app-specific directory
        await _downloadToAppDirectory();
        return;
      }
    }

    isDownloading.value = true;
    downloadProgress.value = 0.0;

    String fileName;
    try {
      final String collectionDate =
          report?.visitDate.toString() ?? DateTime.now().toString();
      final parts = collectionDate.split(' ');
      fileName = parts.length >= 3
          ? "LabReport_${barcode}_${parts.sublist(0, 3).join('')}.pdf"
          : '${barcode}_report.pdf';
    } catch (e) {
      fileName = '${barcode}_report.pdf';
      debugPrint('Error generating file name: $e');
    }

    try {
      final dio = Dio();
      String filePath;

      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkVersion();

        if (sdkInt >= 29) {
          // Use app-specific storage for newer Android versions
          final appDir = await getExternalStorageDirectory();
          filePath = '${appDir!.path}/$fileName';
        } else {
          // Pre-Android 10 can write directly to Downloads
          final downloadsDir = Directory('/storage/emulated/0/Download');
          filePath = '${downloadsDir.path}/$fileName';
        }
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        filePath = '${appDocDir.path}/$fileName';
      }

      debugPrint('Downloading PDF to: $filePath');
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        },
      );

      final file = File(filePath);
      if (await file.exists()) {
        localPath.value = filePath;
        SnackBarService.to.showMessageWithAction(
          message: 'Report Downloaded',
          actionLabel: 'Open file',
          onAction: () => OpenFilex.open(filePath),
        );
      } else {
        throw Exception('Downloaded file not found');
      }
    } catch (e, st) {
      debugPrint('Download error: $e\n$st');
      SnackBarService.to.showMessage(message: 'Failed to download report');
    } finally {
      isDownloading.value = false;
      downloadProgress.value = 0.0;
    }
  }

  // Fallback method to download to app-specific directory
  Future<void> _downloadToAppDirectory() async {
    isDownloading.value = true;
    downloadProgress.value = 0.0;

    try {
      final dio = Dio();
      final appDir = await getExternalStorageDirectory();
      final fileName = '${barcode}_report.pdf';
      final filePath = '${appDir!.path}/$fileName';

      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        },
      );

      final file = File(filePath);
      if (await file.exists()) {
        localPath.value = filePath;
        SnackBarService.to.showMessageWithAction(
          message: 'Report Downloaded to App Folder',
          actionLabel: 'Open file',
          onAction: () => OpenFilex.open(filePath),
        );
      }
    } catch (e) {
      debugPrint('Download to app directory error: $e');
      SnackBarService.to.showMessage(message: 'Failed to download report');
    } finally {
      isDownloading.value = false;
      downloadProgress.value = 0.0;
    }
  }

  Future<void> sharePdf() async {
    if (localPath.value != null) {
      HapticFeedback.selectionClick();
      await Share.shareXFiles(
        [XFile(localPath.value!)],
        text: 'Check out this Report!',
      );
    }
    // else download and then share
    else if (downloadUrl.isNotEmpty && isValidUrl(downloadUrl)) {
      await downloadPdf();
      if (localPath.value != null) {
        HapticFeedback.selectionClick();
        await Share.shareXFiles(
          [XFile(localPath.value!)],
          text: 'Check out this Report!',
        );
      } else {
        SnackBarService.to.showMessage(message: 'No report available to share');
      }
    } else {
      SnackBarService.to.showMessage(message: 'No report available to share');
    }
  }

  void updatePage(int page, int? total) {
    currentPage.value = page;
    if (total != null) totalPages.value = total;
  }

  /// Check permissions on initialization
  Future<void> _checkInitialPermissions() async {
    await _checkStoragePermission();
  }

  /// Get Android SDK version with safe fallback
  Future<int> _getAndroidSdkVersion() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint('Error getting Android SDK: $e');
      return 21; // Conservative default for older Android versions
    }
  }

  /// Check if storage permission is granted (simplified for PDF downloads only)
  Future<void> _checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkVersion();
        debugPrint('Android SDK version: $sdkInt');

        if (sdkInt >= 29) {
          // Android 10+ uses scoped storage, no permission needed for app-specific directories
          hasStoragePermission.value = true;
        } else {
          // Pre-Android 10 needs storage permission for Downloads folder
          final readStatus = await Permission.storage.status;
          hasStoragePermission.value = readStatus.isGranted;
        }
      } else {
        hasStoragePermission.value = true; // iOS
      }
      debugPrint('Storage permission status: ${hasStoragePermission.value}');
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      hasStoragePermission.value = false;
    }
  }

  /// Request storage permission only for older Android versions
  Future<bool> _requestStoragePermission() async {
    debugPrint('Requesting storage permission');
    try {
      if (!Platform.isAndroid) {
        hasStoragePermission.value = true;
        return true;
      }

      final sdkInt = await _getAndroidSdkVersion();

      if (sdkInt >= 29) {
        // Android 10+ doesn't need permission for app-specific storage
        hasStoragePermission.value = true;
        return true;
      } else {
        // Pre-Android 10 needs storage permission
        final status = await Permission.storage.request();
        hasStoragePermission.value = status.isGranted;
        if (!status.isGranted) _handlePermissionDenied(status);
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      hasStoragePermission.value = false;
      return false;
    }
  }

  /// Check if directory is writable
  Future<bool> _isDirectoryWritable(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final testFile =
          File('${dir.path}/test_${DateTime.now().millisecondsSinceEpoch}.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      debugPrint('Directory not writable: $e');
      return false;
    }
  }

  /// Handle permission denied scenarios
  void _handlePermissionDenied(PermissionStatus status) {
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    } else {
      SnackBarService.to.showMessage(
        message:
            'Storage permission is required to download reports to Downloads folder. Files will be saved to app folder instead.',
      );
    }
  }

  /// Show dialog when permission is permanently denied
  void _showPermissionDeniedDialog() {
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Permission Information'),
        content: const Text(
          'Storage permission helps save reports to your Downloads folder. Reports can still be downloaded to the app folder and shared.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            child: const Text('Settings'),
            onPressed: () {
              Get.back();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> shareReportDirectly(PatientReportData report) async {
    try {
      final url = report.reportLink ?? '';
      final code = report.barcode ?? 'unknown';

      if (url.isEmpty || !isValidUrl(url)) {
        SnackBarService.to.showMessage(message: 'Invalid report URL');
        return;
      }

      // build file name
      final fileName = '${code}_report.pdf';
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);

      // if already exists, skip download
      if (!await file.exists()) {
        final dio = Dio();
        await dio.download(url, file.path,
            onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        });
      }

      if (await file.exists()) {
        HapticFeedback.selectionClick();
        await Share.shareXFiles([XFile(file.path)],
            text: 'Check out this Report!');
      } else {
        SnackBarService.to
            .showMessage(message: 'Failed to prepare report for sharing');
      }
    } catch (e, st) {
      debugPrint('Direct share error: $e\n$st');
      SnackBarService.to.showMessage(message: 'Error sharing report');
    }
  }

  Future<void> shareToWhatsAppDirectly(PatientReportData report) async {
    try {

      final code = report.barcode ?? 'unknown';
      final mobile = report.mobile ?? '';
      // show bottomsheet sharing the report the to mobile number, also give option for different mobile number or cancel

      //api call



    } catch (e, st) {
      debugPrint('WhatsApp share error: $e\n$st');
      SnackBarService.to
          .showMessage(message: 'Error sharing report on WhatsApp');
    }
  }

}
