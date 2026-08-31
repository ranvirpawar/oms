import 'package:flutter/material.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../controller/passkey_controller.dart';
import 'package:get/get.dart';

// View
class PasskeyScreen extends StatelessWidget {
  final String userId;

  PasskeyScreen({super.key, required this.userId});

  final PasskeyController _controller = Get.put(PasskeyController());

  @override
  Widget build(BuildContext context) {
    _controller.fetchPasskey(userId);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Your Pass-Key'),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Obx(() {
          if (_controller.isLoading.value) {
            return const CircularProgressIndicator();
          }
          if (_controller.error.value.isNotEmpty) {
            return Text(
              _controller.error.value,
              style: const TextStyle(color: Colors.red),
            );
          }
          if (_controller.passkeyData.value == null) {
            return const Text('No passkey available');
          }

          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your Passkey for Today',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(2),
                      },
                      children: [
                        _buildTableRow(
                            'Passkey', _controller.passkeyData.value!.passkey),
                        _buildTableRow('User ID',
                            _controller.passkeyData.value!.userId.toString()),
                        _buildTableRow(
                            'Generated At',
                            _parseDate(
                                _controller.passkeyData.value!.generatedAt)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _parseDate(String dateStr) {
    try {
      final regex = RegExp(r'\/Date\((\d+)\)\/');
      final match = regex.firstMatch(dateStr);
      if (match != null) {
        final timestamp = int.parse(match.group(1)!);
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }
}
