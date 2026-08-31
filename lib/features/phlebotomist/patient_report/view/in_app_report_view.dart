
import 'package:flutter/material.dart';

import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';



import '../../../../constants/app_strings.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../controller/in_app_report_view_controller.dart';

class ReportPdfViewerPage extends StatelessWidget {
  final String patientName;

  ReportPdfViewerPage({super.key, required this.patientName});

  // Instantiate the new controller and pass arguments
  final controller = Get.put(ReportPdfViewerController(),
      tag: Get.arguments.hashCode.toString());

  @override
  Widget build(BuildContext context) {
    // Trigger loadPdf after the build phase no need as onInit already calls it
    /*WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadPdf();
    });*/

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: HelperMethods.capitalizeFirstLetter(patientName),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return  Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(value: controller.downloadProgress.value,),
              const SizedBox(height: 16),
              Text('${AppStrings.loadingReport}${(controller.downloadProgress.value * 100).toStringAsFixed(0)}%'),
            ],
          ));
        } else if (controller.localPath.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load Report',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: controller.loadPdf,
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.openInBrowser,
                  child: const Text('Open In Browser'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              PDFView(
                filePath: controller.localPath.value!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                fitEachPage: true,
                // Enable texture layer for better rendering
                onRender: (pages) {
                  controller.totalPages.value = pages ?? 0;
                },
                onViewCreated: (viewController) {
                  controller.pdfController = viewController;
                },
                onPageChanged: (page, total) {
                  if (page != null) controller.updatePage(page, total);
                },
                onError: (error) {
                  debugPrint('PDFView error: $error');
                  // Delay snackbar to avoid build-time issues
                  controller.showCuteAlertDialog(controller.downloadUrl);
                  /*Future.microtask(() {
                    Get.snackbar('Error', 'Failed to render PDF: $error');
                  });*/
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Obx(() => controller.totalPages.value > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${controller.currentPage.value + 1} / ${controller.totalPages.value}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : const SizedBox.shrink()),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(
              (){
                if(controller.isLoading.value || controller.localPath.value == null){
                  return const SizedBox.shrink();
                }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => FloatingActionButton(
                    heroTag: 'share',
                    onPressed: controller.localPath.value != null
                        ? controller.sharePdf
                        : null,
                    child: const Icon(Icons.share),
                  )),
              const SizedBox(height: 16),
              Obx(() => Stack(
                    alignment: Alignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: 'download',
                        onPressed: controller.isDownloading.value
                            ? null
                            : () {
                                debugPrint('Download button pressed');
                                controller.downloadPdf();
                              },
                        backgroundColor: controller.isDownloading.value
                            ? Colors.grey
                            : Colors.green,
                        child: controller.isDownloading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.download),
                      ),
                      if (controller.isDownloading.value &&
                          controller.downloadProgress.value > 0)
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: controller.downloadProgress.value,
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                    ],
                  )),
            ],
          );
        }
      ),
    );
  }
}
