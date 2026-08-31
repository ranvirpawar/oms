import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:lifenity_connect/utils/widgets/modern_dropdown.dart';

import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../controller/sample_accept_controller.dart';
import '../model/resource_model.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';


class SampleAcceptView extends StatelessWidget {
  const SampleAcceptView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SampleAcceptController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Sample Accept'),
      body: Obx(() {
        return CustomScrollView(
          slivers: [

            /// ================= DATE SELECTOR (SCROLLS AWAY) =================
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: _buildDateSelector(controller),
              ),
            ),

            /// ================= PINNED DESIGNATION + SEARCH =================
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: 150,
                child: Container(
                  color: Colors.white,
                  padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [

                      /// DESIGNATION (UNCHANGED STYLE)
                      ModernDropdown(
                        label: 'Select Designation',
                        value:
                        controller.selectedDesignationName,
                        items: controller.designations
                            .map((designation) =>
                        designation['name']!)
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            final designation =
                            controller.designations
                                .firstWhere(
                                  (item) =>
                              item['name'] ==
                                  newValue,
                              orElse: () => {
                                'id': '7',
                                'name': 'Runner Boy'
                              },
                            );
                            controller.onDesignationChanged(
                                designation['id']);
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      /// SEARCH FIELD
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius:
                          BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey
                                  .withOpacity(0.2)),
                        ),
                        child: TextField(
                          onChanged:
                          controller.onSearchChanged,
                          decoration:
                          const InputDecoration(
                            hintText:
                            'Search resource...',
                            prefixIcon:
                            Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding:
                            EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// ================= TABLE HEADER (UNCHANGED) =================
            if (controller.resourcesList.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildTableHeader(),
              ),

            /// ================= LOADING =================
            if (controller.isLoading.value)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )

            /// ================= EMPTY =================
            else if (controller.resourcesList.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No resources found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try selecting a different date or designation',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )

            /// ================= LIST (YOUR EXACT UI) =================
            else
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: AppColors.primary
                              .withOpacity(0.3)),
                      right: BorderSide(
                          color: AppColors.primary
                              .withOpacity(0.3)),
                      bottom: BorderSide(
                          color: AppColors.primary
                              .withOpacity(0.3)),
                    ),
                    borderRadius:
                    const BorderRadius.only(
                      bottomLeft:
                      Radius.circular(12),
                      bottomRight:
                      Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                    const BorderRadius.only(
                      bottomLeft:
                      Radius.circular(12),
                      bottomRight:
                      Radius.circular(12),
                    ),
                    child: RefreshIndicator(
                      onRefresh:
                      controller.loadResourcesData,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        padding:
                        const EdgeInsets.fromLTRB(
                            0, 0, 0, 16),
                        itemCount:
                        controller.resourcesList.length,
                        separatorBuilder:
                            (context, index) =>
                            Divider(
                              height: 1,
                              color: Colors.grey
                                  .withOpacity(0.2),
                              thickness: 1,
                            ),
                        itemBuilder:
                            (context, index) {
                          final resource =
                          controller
                              .resourcesList[index];
                          return _buildResourceTile(
                              resource,
                              controller);
                        },
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        );
      }),
    );
  }

  /// ================= DATE SELECTOR =================
  Widget _buildDateSelector(
      SampleAcceptController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border:
        Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
              AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              AppAssets.calendarIcon,
              color: AppColors.primary,
              height: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() => Text(
                  DateFormat('dd MMM yyyy')
                      .format(controller
                      .selectedDate.value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                )),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                controller.selectDate(Get.context!),
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= TABLE HEADER (UNCHANGED) =================
  Widget _buildTableHeader() {
    return Container(

      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 16),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
          AppColors.primary.withOpacity(0.1),
          borderRadius:
          const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          border: Border.all(
              color: AppColors.primary
                  .withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 46),
            Expanded(
              flex: 4,
              child: Text(
                'Resource Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Visited',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= RESOURCE TILE (UNCHANGED) =================
  Widget _buildResourceTile(
      ResourcesData resource,
      SampleAcceptController controller) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () =>
            controller.onResourceTap(resource),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary
                          .withOpacity(0.8),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    resource.name.isNotEmpty
                        ? resource.name[0]
                        .toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style:
                      const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Colors.black87,
                      ),
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (resource.mobNo
                        .isNotEmpty)
                      Text(
                        resource.mobNo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors
                              .grey[500],
                        ),
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                      vertical: 6,
                      horizontal:
                      12),
                  decoration:
                  BoxDecoration(
                    color: Colors.green
                        .withOpacity(0.1),
                    borderRadius:
                    BorderRadius
                        .circular(8),
                  ),
                  child: Text(
                    resource.visitedFacility
                        .toString(),
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight
                          .w600,
                      color:
                      Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= PINNED HEADER DELEGATE =================
class _PinnedHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _PinnedHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(
      covariant SliverPersistentHeaderDelegate
      oldDelegate) =>
      true;
}


