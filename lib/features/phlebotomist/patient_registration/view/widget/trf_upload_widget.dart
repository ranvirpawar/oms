import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_assets.dart';

class TrfUploadWidget extends StatelessWidget {
  final RxList<File> selectedFiles;
  final VoidCallback onAddFiles;
  final Function(int) onRemoveFile;

  const TrfUploadWidget({
    super.key,
    required this.selectedFiles,
    required this.onAddFiles,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  AppAssets.cameraIcon,
                  color: Theme.of(context).primaryColor,
                  height: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRF Upload',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                     /* SizedBox(height: 2),
                      Text(
                        'Upload Test Request Form images',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),*/
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Add Files Button
                InkWell(
                  onTap: onAddFiles,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).primaryColor.withOpacity(0.02),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add TRF Photos',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Selected Files List
                Obx(() {
                  if (selectedFiles.isEmpty) {
                    return const SizedBox.shrink();
                    /*return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No files selected',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );*/
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedFiles.length,
                        separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = selectedFiles[index];
                          final fileName = file.path.split('/').last;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[200]!,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  image: DecorationImage(
                                    image: FileImage(file),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              title: Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _formatFileSize(file.lengthSync()),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.red[400],
                                  size: 20,
                                ),
                                onPressed: () => onRemoveFile(index),
                                tooltip: 'Remove',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}