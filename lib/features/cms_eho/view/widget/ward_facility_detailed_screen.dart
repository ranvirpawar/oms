// ward_facility_detail_screen.dart
//
// Drill-down screen opened from Ward card tap.
// Reuses EXACT same UI components from existing screen.
// No UI redesign.
// Only filtered by selected ward.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';


import '../../../../theme/app_colors.dart';
import '../../model/facility_detail_model.dart';
import '../facility_detail_screen.dart';




class WardFacilityDetailScreen extends ConsumerStatefulWidget {
  final String wardName;
  final List<FacilityDetailModel> wardItems;

  const WardFacilityDetailScreen({
    super.key,
    required this.wardName,
    required this.wardItems,
  });

  @override
  ConsumerState<WardFacilityDetailScreen> createState() =>
      _WardFacilityDetailScreenState();
}

class _WardFacilityDetailScreenState
    extends ConsumerState<WardFacilityDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animController;

  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.wardItems.where((e) {
      if (_searchQuery.isEmpty) return true;

      return e.facilityName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    final grouped = <String, List<FacilityDetailModel>>{};

    for (final item in filteredItems) {
      grouped.putIfAbsent(item.facilityName, () => []).add(item);
    }

    final totalTarget =
    filteredItems.fold(0, (s, e) => s + e.yearlyTarget);

    final totalPatients =
    filteredItems.fold(0, (s, e) => s + e.patCount);

    final overallPct = totalTarget > 0
        ? (totalPatients / totalTarget * 100).clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      appBar: CustomAppBar(title:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ward',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            widget.wardName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),),/*PreferredSize(


        preferredSize: const Size.fromHeight(180),
        child: _buildAppBar(grouped.length),
      ),*/

      body: Column(
        children: [
          const SizedBox(height: 10),

          Container(


            margin: const EdgeInsets.symmetric(horizontal: 16),
            /*  decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),*/
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() {
                  _searchQuery = v.trim();
                });
              },
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              cursorColor: const Color(0xFF64748B),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,

                // SEARCH ICON
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 8,
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),

                prefixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 42,
                ),

                // HINT
                hintText: 'Search facilities...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),

                // CLEAR BUTTON
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    splashRadius: 18,
                    onPressed: () {
                      _searchCtrl.clear();

                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 14,
                      ),
                    ),
                  ),
                ),

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? _buildEmptyState()
                : ListView(
              padding: EdgeInsets.zero,
              children: [
                
                SummaryBanner(
                  totalTarget: totalTarget,
                  totalPatients: totalPatients,
                  overallPct: overallPct.toDouble(),
                ),
            
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    '${grouped.length} facilit${grouped.length != 1 ? 'ies' : 'y'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(
                      grouped.length,
                          (index) {
                        final entry = grouped.entries.elementAt(index);
            
                        return FacilityGroup(
                          facilityName: entry.key,
                          categories: entry.value,
                          animController: _animController,
                          groupIndex: index,
                        );
                      },
                    ),
                  ),
                ),
            
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.primary.withOpacity(0.35),
            size: 54,
          ),

          const SizedBox(height: 14),

          const Text(
            'No facilities found',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Try searching with another keyword',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}