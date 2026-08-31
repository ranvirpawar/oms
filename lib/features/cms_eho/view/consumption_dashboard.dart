

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/consumption_error_view.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/consumption_facility_dropdown.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/facility_card.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/sort_button.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/summary_stats_header.dart';

import '../../../theme/app_colors.dart';
import '../model/facility_detail_model.dart';
import '../provider/consumption_providers.dart';
import '../model/consumption_model.dart';
import '../provider/facility_detail_providers.dart';
import 'facility_detail_screen.dart';
import 'widget/consumption_skeleton.dart';
import 'package:lifenity_connect/utils/helper_functions/debug_print.dart';
// ── ConsumerStatefulWidget ────────────────────────────────────────────────────
// Like StatefulWidget but it can access Riverpod providers via `ref`.
class ConsumptionDashboard extends ConsumerStatefulWidget {
  const ConsumptionDashboard({super.key});

  @override
  ConsumerState<ConsumptionDashboard> createState() =>
      _ConsumptionDashboardState();
}

class _ConsumptionDashboardState extends ConsumerState<ConsumptionDashboard> {
  @override
  Widget build(BuildContext context) {
    // ref.watch() → rebuilds this widget whenever the provider state changes.
    final consumptionState = ref.watch(consumptionNotifierProvider);
    final groupedData = ref.watch(filteredConsumptionProvider);
    final selectedFacility = ref.watch(facilityFilterProvider);
    final facilityNames = ref.watch(facilityNamesProvider);
    final selectedSort = ref.watch(sortOptionProvider);
    final selectedYearId = ref.watch(selectedYearProvider);
    final financialYears = ref.watch(financialYearsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: NestedScrollView(
        // NestedScrollView lets the AppBar collapse as you scroll.
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(
            selectedFacility: selectedFacility,
            facilityNames: facilityNames,
            selectedSort: selectedSort,
            isLoading: consumptionState.isLoading,
            selectedYearId: selectedYearId,       // ✅
            financialYears: financialYears,       // ✅
          ),
        ],
        body: _buildBody(consumptionState, groupedData),
      ),
    );
  }

  // ── Sliver (collapsible) AppBar ─────────────────────────────────────────────
  Widget _buildSliverAppBar({
    required String selectedFacility,
    required List<String> facilityNames,
    required SortOption selectedSort,
    required bool isLoading,
    required int selectedYearId,                                    // ✅
    required AsyncValue<List<ProjectFinancialYear>> financialYears, // ✅
  }) {
    final yearLabel = financialYears.whenOrNull(
      data: (years) => years
          .firstWhere(
            (y) => y.yearId == selectedYearId,
        orElse: () => years.first,
      )
          .yearDescription,
    ) ?? '...';
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title:  const Text(
        'Consumption Dashboard',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
      leadingWidth: 20,
        actions: [
          GestureDetector(
            onTap: () => _showYearPicker(financialYears, selectedYearId),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white38),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /*const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),*/
                    Text(
                      yearLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),

            gradient: AppColors.primaryGradient,
          ),

          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
              child: Row(
                children: [
                  // ── Facility Filter Dropdown ──────────────────────────
                  Expanded(
                    child: ConsumptionFacilityDropdown(
                      selected: selectedFacility,
                      options: facilityNames,
                      onChanged: (val) {
                        // ref.read() → reads the provider without subscribing.
                        // Use read() for one-shot actions (button taps, etc.).
                        ref.read(facilityFilterProvider.notifier).state = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ── Sort Button ───────────────────────────────────────
                  SortButton(
                    selected: selectedSort,
                    onSelected: (sort) {
                      ref.read(sortOptionProvider.notifier).state = sort;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Main Body ───────────────────────────────────────────────────────────────
  Widget _buildBody(
    ConsumptionState state,
    List<MapEntry<String, List<ConsumptionModel>>> groupedData,
  ) {
    // Loading state
    if (state.isLoading) {
      return const ConsumptionSkeleton();
    }

    // Error state
    if (state.error != null) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(consumptionNotifierProvider.notifier).refresh(),
      );
    }

    // Empty state
    if (groupedData.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.primary),
        ),
      );
    }

    // Data state — show summary header + cards
    return RefreshIndicator(
      onRefresh: () => ref.read(consumptionNotifierProvider.notifier).refresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // Stats header
          SliverToBoxAdapter(child: SummaryStatsHeader(data: state.data)),

          // Card count label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                '${groupedData.length} facility type${groupedData.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Facility cards list
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = groupedData[index];
              return FacilityCard(
                facilityName: entry.key,
                categories: entry.value,
                onTap: () {
                  // todo moved to routemanager
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FacilityDetailScreen(
                        fTypeId: entry.value.first.fTypeId,
                        facilityName: entry.key,
                      ),
                    ),
                  );
                },
              );
            }, childCount: groupedData.length),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
  void _showYearPicker(
      AsyncValue<List<ProjectFinancialYear>> financialYears,
      int selectedYearId,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => financialYears.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(
          height: 120,
          child: Center(child: Text('Failed to load years: $e')),
        ),
        data: (years) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // const SizedBox(height: 12),
            /*Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),*/
            const SizedBox(height: 16),
            const Text(
              'Select Financial Year',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...years.map(
                  (year) {
                final isSelected = year.yearId == selectedYearId;
                return ListTile(
                  title: Text(year.yearDescription),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  titleTextStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : Colors.black87,
                  ),
                  onTap: () {
                    //on tap debug
                    CustomDebugFunction.log('Selected year in consumption dashboard: ${year.yearDescription}');
                    ref.read(selectedYearProvider.notifier).state = year.yearId; // ✅ triggers re-fetch
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
