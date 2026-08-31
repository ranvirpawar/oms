  import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InvoiceFileUploadWidget extends StatelessWidget {
  final RxList<File> selectedImageFiles;
  final Rx<File?> selectedPdfFile;
  final RxString selectedPdfFileName;
  final VoidCallback onAddImages;
  final VoidCallback onAddPdf;
  final Function(int) onRemoveImage;
  final VoidCallback onRemovePdf;

  const InvoiceFileUploadWidget({
    super.key,
    required this.selectedImageFiles,
    required this.selectedPdfFile,
    required this.selectedPdfFileName,
    required this.onAddImages,
    required this.onAddPdf,
    required this.onRemoveImage,
    required this.onRemovePdf,
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
                Icon(
                  Icons.upload_file,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Invoice Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Upload PDF or Images',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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
                // Upload Buttons Row
                Row(
                  children: [
                    // Add Images Button
                    Expanded(
                      child: InkWell(
                        onTap: onAddImages,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.02),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Theme.of(context).primaryColor,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Images',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Add PDF Button
                    Expanded(
                      child: InkWell(
                        onTap: onAddPdf,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red.withOpacity(0.02),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.picture_as_pdf_outlined,
                                color: Colors.red[700],
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add PDF',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // PDF File Display
                Obx(() {
                  if (selectedPdfFile.value == null) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.shade200,
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
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red[700],
                          size: 30,
                        ),
                      ),
                      title: Text(
                        selectedPdfFileName.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _formatFileSize(selectedPdfFile.value!.lengthSync()),
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
                        onPressed: onRemovePdf,
                        tooltip: 'Remove',
                      ),
                    ),
                  );
                }),

                // Selected Images List
                Obx(() {
                  if (selectedImageFiles.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selected Images (${selectedImageFiles.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedImageFiles.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = selectedImageFiles[index];
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
                                onPressed: () => onRemoveImage(index),
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
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}