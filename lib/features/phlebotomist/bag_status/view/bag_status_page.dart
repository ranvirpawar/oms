// bag_status_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../controller/bag_status_controller.dart';
import '../model/bag_status_model.dart';

class BagStatusPage extends StatelessWidget {
  const BagStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BagStatusController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(
        title: 'Bag Status Tracking',

      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshBagStatus,
        child: Obx(() => _buildBody(controller)),
      ),
    );
  }

  Widget _buildBody(BagStatusController controller) {
    if (controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load bag status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: controller.loadBagStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 🔍 Search Bar Widget
        _buildSearchBar(controller),
        Expanded(
          child: !controller.hasBags
              ? _buildEmptyState() // Show empty state if filtered list is empty
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16,
                      16), // Remove top padding so it sits flush with search
                  itemCount:
                      controller.filteredBagGroups.length, // Use filtered list
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemBuilder: (context, index) {
                    final bagGroup = controller.filteredBagGroups[index];
                    return BagStatusCard(bagGroup: bagGroup, index: index + 1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BagStatusController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller.searchController,
        onChanged: (val) => controller.filterBags(val),
        decoration: InputDecoration(
          hintText: 'Search bag by last four digits (e.g. 0016)',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon: controller.searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    controller.searchController.clear();
                    controller.filterBags(''); // Reset search
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No bags found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or check availability',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class BagStatusCard extends StatefulWidget {
  final BagGroup bagGroup;
  final int index;

  const BagStatusCard({super.key, required this.bagGroup, required this.index});

  @override
  State<BagStatusCard> createState() => _BagStatusCardState();
}

class _BagStatusCardState extends State<BagStatusCard>
    with SingleTickerProviderStateMixin {
  final RxBool isExpanded = false.obs;
  late AnimationController _animationController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    HapticFeedback.lightImpact();
    isExpanded.value = !isExpanded.value;
    if (isExpanded.value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago,${DateFormat('dd MMM yyyy, hh:mm a').format(dateTime)}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago, ${DateFormat('dd MMM yyyy, hh:mm a').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago, ${DateFormat('dd MMM yyyy,hh:mm a').format(dateTime)}';
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.bagGroup.latestTransaction;
    final hasHistory = widget.bagGroup.transactions.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: hasHistory ? _toggleExpansion : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center, // Center the number
                          decoration: BoxDecoration(
                            // Using circular shape
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                          child: Text(
                            '${widget.index}', // Display Sr. No.
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SelectableText(
                                      widget.bagGroup.bagcode,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (hasHistory)
                                    RotationTransition(
                                      turns: _iconAnimation,
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey.shade600,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                latest.currentStage,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(latest.parsedDateTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasHistory)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Tap to view ${widget.bagGroup.transactions.length - 1} previous status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (isExpanded.value && hasHistory) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status History',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...widget.bagGroup.transactions
                                .skip(1)
                                .map((transaction) => _buildHistoryItem(
                                      transaction,
                                      transaction ==
                                          widget.bagGroup.transactions.last,
                                    ))
                                ,
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BagTransaction transaction, bool isLast) {
    // Use IntrinsicHeight so the left line stretches to match the right text height
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LEFT SIDE (Timeline) ---
          SizedBox(
            width: 20, // Fixed width for the timeline column
            child: Column(
              children: [
                // The Dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.primary900,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white,
                          width: 2), // Optional: white border makes it pop
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                        )
                      ]),
                ),
                // The Line
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      size: const Size(
                          2, double.infinity), // Width 2, Height fills space
                      painter: DashedLineVerticalPainter(
                        color: AppColors.primary300,
                        dashHeight: 4,
                        dashSpace: 3,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // --- RIGHT SIDE (Content) ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Align the text visually with the dot
                // The dot is 10px, so we might need a slight offset if text is large
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Text(
                    transaction.currentStage,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(transaction.parsedDateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                if (!isLast) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLineVerticalPainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashSpace;
  final double strokeWidth;

  DashedLineVerticalPainter({
    this.color = Colors.grey,
    this.dashHeight = 4.0,
    this.dashSpace = 4.0,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;

    while (startY < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(
            (size.width - strokeWidth) / 2, startY, strokeWidth, dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
