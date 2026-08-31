import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:lifenity_connect/routes/route_manager.dart';

import '../../../../../services/snackbar_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/recollection_tests_controller.dart';
import '../../model/rejection_reason_model.dart';

class DenyRemarkBottomSheet extends StatefulWidget {
  final RecollectTestsController controller;

  const DenyRemarkBottomSheet({super.key, required this.controller});

  @override
  State<DenyRemarkBottomSheet> createState() => _DenyRemarkBottomSheetState();
}

class _DenyRemarkBottomSheetState extends State<DenyRemarkBottomSheet> {
  // Local state to handle confirmation flow
  bool showConfirmation = false;
  bool isProcessing = false;

  void _toggleConfirmation() {
    if (widget.controller.selectedDenyRemark.value == null) {
      SnackBarService.to.showMessage(message: 'Please select a deny remark');

      return;
    }

    setState(() {
      showConfirmation = !showConfirmation;
    });
  }

  Future<void> _processDenial() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final success = await widget.controller.denyRecollection();

      if (success && mounted) {
        // Close the bottom sheet on success
        Navigator.of(context).pop();
        RouteManager.navigateToSampleRecollection(true);
      }
    } catch (e) {
      // Error is already handled in the controller
      debugPrint('Error in _processDenial: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
          showConfirmation = false;
        });
      }
    }
  }

  void _safeBack() {
    if (isProcessing) return;

    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
      Get.back();
      /*Navigator.of(context).pop();*/
    } catch (e) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppAssets.testTube,
                  width: 20,
                  height: 20,
                  color: showConfirmation ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  showConfirmation
                      ? 'Confirm Denial'
                      : 'Deny Test Recollection',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: showConfirmation ? AppColors.error : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                if (!isProcessing)
                  IconButton(
                    icon: Icon(
                      showConfirmation ? Icons.arrow_back : Icons.close,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed:
                        showConfirmation ? _toggleConfirmation : _safeBack,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Content based on state
            if (!showConfirmation) ...[
              // Deny remark selection
              // Deny remark selection
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: Obx(() {
                  if (widget.controller.denyRemarkList.isEmpty) {
                    return const Center(
                      child: Text('No deny remarks available.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.controller.denyRemarkList.length,
                    itemBuilder: (context, index) {
                      final remark = widget.controller.denyRemarkList[index];

                      return Obx(() {
                        final isSelected =
                            widget.controller.selectedDenyRemark.value ==
                                remark;

                        return Container(
                          key: ValueKey(remark.rid ?? remark.denyRemark),
                          // Ensures rebuild on selection change
                          margin: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 4),
                          child: Material(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                debugPrint(
                                    'InkWell onTap: selecting ${remark.denyRemark}');
                                widget.controller.selectedDenyRemark.value =
                                    remark;
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    Radio<DenyRemarkModel>(
                                      value: remark,
                                      groupValue: widget
                                          .controller.selectedDenyRemark.value,
                                      onChanged: (DenyRemarkModel? value) {
                                        debugPrint(
                                            'Radio onChanged: selected ${value?.denyRemark}');
                                        widget.controller.selectedDenyRemark
                                            .value = value;
                                      },
                                      activeColor: AppColors.primary,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        remark.denyRemark,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  );
                }),
              ),

              const SizedBox(height: 8),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  onPressed: _toggleConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Deny Selected Tests',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else ...[
              // Confirmation view
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                    Text(
                      'Are you sure you want to deny recollection of the selected test(s)?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Show selected deny remark
                    Obx(() {
                      final selectedRemark =
                          widget.controller.selectedDenyRemark.value;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reason: ${selectedRemark?.denyRemark ?? "Unknown"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Show selected tests count
                    Obx(() {
                      final testCount = widget.controller.selectedTests.length;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.science_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tests to deny: $testCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Confirmation buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isProcessing ? null : _toggleConfirmation,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(double.infinity, 38),
                        foregroundColor: AppColors.secondary,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _processDenial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(double.infinity, 38),
                        elevation: 0,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Confirm Denial',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/*
class DenyRemarkBottomSheet extends StatefulWidget {
  final RecollectTestsController controller;

  const DenyRemarkBottomSheet({super.key, required this.controller});

  @override
  State<DenyRemarkBottomSheet> createState() => _DenyRemarkBottomSheetState();
}

class _DenyRemarkBottomSheetState extends State<DenyRemarkBottomSheet> {
  void _showConfirmationDialog() {
    if (!mounted) return;
    final dialogContext = context;
    RxBool isLoading = false.obs;

    Get.dialog(
      StatefulBuilder(
        builder: (BuildContext innerContext, StateSetter setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: CupertinoColors.systemBackground,
            elevation: 2,
            titlePadding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            title: const Text(
              'Confirm Denial',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            content: const Text(
              'Are you sure you want to deny recollection of the selected test(s)?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading.value ? null : () {
                        Navigator.of(innerContext).pop();  // No need for mounted here; innerContext is dialog's
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(double.infinity, 36),
                        foregroundColor: AppColors.secondary,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Obx(() {
                      if (!mounted) return const SizedBox();
                      return ElevatedButton(
                        onPressed: isLoading.value ? null : () async {
                          if (widget.controller.selectedDenyRemark.value == null) {
                            Get.snackbar('Error', 'Please select a deny remark.');
                            return;
                          }
                          isLoading.value = true;
                          setDialogState(() {});  // Force StatefulBuilder to rebuild for loading UI
                          try {
                            await widget.controller.denyRecollection();
                            isLoading.value = false;
                            setDialogState(() {});  // Update to show "Deny" text again (briefly)
                            if (mounted && innerContext.mounted) {  // Check both for safety
                              Navigator.of(innerContext).pop();  // Close dialog on success
                              _safeBack();  // Now close the sheet after success
                            }
                          } catch (e) {
                            isLoading.value = false;
                            setDialogState(() {});  // Force rebuild to hide spinner
                            Get.snackbar('Error', 'Failed to deny: $e');  // Context-free snackbar
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(double.infinity, 36),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: isLoading.value
                            ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text('Deny'),
                      );
                    }),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,  // Always false to prevent dismiss during loading
    );
  }

  // Safe back navigation method (unchanged)
  void _safeBack() {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
      Navigator.of(Get.overlayContext!).pop();
    } catch (e) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Remove early returns from build; handle in parent button onPressed to avoid build-time issues
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppAssets.testTube,
                width: 20,
                height: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Deny Test Recollection',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: _safeBack,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Obx(() {  // Single Obx for the whole list
                if (widget.controller.denyRemarkList.isEmpty) {
                  return const Center(child: Text('No deny remarks available.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.controller.denyRemarkList.length,
                  itemBuilder: (context, index) {
                    final remark = widget.controller.denyRemarkList[index];
                    final isSelected = widget.controller.selectedDenyRemark.value == remark;
                    return GestureDetector(
                      onTap: () {
                        widget.controller.selectedDenyRemark.value = remark;
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Radio<DenyRemarkModel>(
                              value: remark,
                              groupValue: widget.controller.selectedDenyRemark.value,
                              onChanged: (DenyRemarkModel? value) {
                                widget.controller.selectedDenyRemark.value = value;
                              },
                              activeColor: AppColors.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                remark.denyRemark,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                if (widget.controller.selectedDenyRemark.value == null) {
                  Get.snackbar('Error', 'Please select a deny remark.');
                  return;
                }
                // Don't close sheet here; show dialog while sheet is open
                _showConfirmationDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Deny Selected Tests',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
