// facility_detail_screen.dart
//
// Opened when the user taps a FacilityCard on the ConsumptionDashboard.
// Shows per-category breakdown (Basic A / Basic B / Advance) for that facility.
// Has a project-year filter chip row at the top.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/consumption_skeleton.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/sort_button.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/ward_facility_detailed_screen.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/year_row_with_search.dart';
import '../../../theme/app_colors.dart';
import '../provider/consumption_providers.dart';
import '../provider/facility_detail_providers.dart';
import '../model/facility_detail_model.dart';
// facility_detail_screen.dart
//
// Opened when the user taps a FacilityCard on the ConsumptionDashboard.
// Has two tabs:
//   • By Ward     — facilities grouped by ward code, with aggregate KPIs
//   • By Facility — same card-based view as before (no change)
// Has a project-year filter chip row + search in the SliverAppBar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/consumption_skeleton.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/sort_button.dart';
import 'package:lifenity_connect/features/cms_eho/view/widget/year_row_with_search.dart';
import '../../../theme/app_colors.dart';
import '../provider/consumption_providers.dart';
import '../provider/facility_detail_providers.dart';
import '../model/facility_detail_model.dart';

class FacilityDetailScreen extends ConsumerStatefulWidget {
  final int fTypeId;
  final String facilityName;

  const FacilityDetailScreen({
    super.key,
    required this.fTypeId,
    required this.facilityName,
  });

  @override
  ConsumerState<FacilityDetailScreen> createState() =>
      _FacilityDetailScreenState();
}

class _FacilityDetailScreenState extends ConsumerState<FacilityDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _animController.dispose();
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      Future.microtask(() => _searchFocus.requestFocus());
    } else {
      _searchCtrl.clear();
      ref.read(detailSearchQueryProvider.notifier).state = '';
      _searchFocus.unfocus();
    }
  }

  DetailArg _arg(int yearId) =>
      DetailArg(fTypeId: widget.fTypeId, yearId: yearId);

  @override
  Widget build(BuildContext context) {
    final selectedYear = ref.watch(selectedYearProvider);
    final arg = _arg(selectedYear);
    final detailState = ref.watch(facilityDetailProvider(arg));
    final yearsAsync = ref.watch(financialYearsProvider);
    final sortOption = ref.watch(detailSortOptionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          _buildAppBar(
            yearsAsync: yearsAsync,
            selectedYear: selectedYear,
            isLoading: detailState.isLoading,
            sortOption: sortOption,
          ),
        ],
        body: _buildBody(detailState, arg),
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────────
  Widget _buildAppBar({
    required AsyncValue<List<ProjectFinancialYear>> yearsAsync,
    required int selectedYear,
    required bool isLoading,
    required SortOption sortOption,
  }) {
    return SliverAppBar(
      // Extra height to accommodate TabBar below the year chips
      expandedHeight: 200,
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
      leadingWidth: 30,
      // ── Collapsed bar title + sort ──────────────────────────────────────────
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Facility Type',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            widget.facilityName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        SortButton(
          selected: sortOption,
          onSelected: (opt) =>
          ref.read(detailSortOptionProvider.notifier).state = opt,
        ),
        const SizedBox(width: 8),
      ],
      // ── Expanded area: year chips + search + tab bar ───────────────────────
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
              padding: const EdgeInsets.fromLTRB(16, 58, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Project Year',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  YearRowWithSearch(
                    yearsAsync: yearsAsync,
                    selectedYear: selectedYear,
                    searchOpen: _searchOpen,
                    searchCtrl: _searchCtrl,
                    searchFocus: _searchFocus,
                    onSearchChanged: (v) =>
                    ref.read(detailSearchQueryProvider.notifier).state = v,
                    onToggleSearch: _toggleSearch,
                    onYearSelected: (yearId) =>
                    ref.read(selectedYearProvider.notifier).state = yearId,
                  ),
                  const SizedBox(height: 12),
                  // ── Tab Bar ───────────────────────────────────────────────
                  TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_city_rounded, size: 15),
                            SizedBox(width: 6),
                            Text('By Ward'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_hospital_rounded, size: 15),
                            SizedBox(width: 6),
                            Text('By Facility'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────
  Widget _buildBody(FacilityDetailState state, DetailArg arg) {
    if (state.isLoading) return const ConsumptionSkeleton();

    if (state.error != null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(facilityDetailProvider(arg).notifier).refresh(),
      );
    }

    if (state.data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.primary),
        ),
      );
    }

    // Summary numbers from raw data (not filtered) for the banner
    final totalTarget = state.data.fold(0, (s, e) => s + e.yearlyTarget);
    final totalPatients = state.data.fold(0, (s, e) => s + e.patCount);
    final overallPct = totalTarget > 0
        ? (totalPatients / totalTarget * 100).clamp(0.0, 100.0)
        : 0.0;

    return TabBarView(
      controller: _tabController,
      children: [
        // ── Tab 0: By Ward ──────────────────────────────────────────────────
        _WardTab(
          arg: arg,
          totalTarget: totalTarget,
          totalPatients: totalPatients,
          overallPct: overallPct.toDouble(),
          animController: _animController,
          onRefresh: () =>
              ref.read(facilityDetailProvider(arg).notifier).refresh(),
        ),
        // ── Tab 1: By Facility (unchanged) ──────────────────────────────────
        _FacilityTab(
          arg: arg,
          totalTarget: totalTarget,
          totalPatients: totalPatients,
          overallPct: overallPct.toDouble(),
          animController: _animController,
          onRefresh: () =>
              ref.read(facilityDetailProvider(arg).notifier).refresh(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 — By Ward
// ─────────────────────────────────────────────────────────────────────────────
class _WardTab extends ConsumerWidget {
  final DetailArg arg;
  final int totalTarget;
  final int totalPatients;
  final double overallPct;
  final AnimationController animController;
  final Future<void> Function() onRefresh;

  const _WardTab({
    required this.arg,
    required this.totalTarget,
    required this.totalPatients,
    required this.overallPct,
    required this.animController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wards = ref.watch(wardGroupedDetailProvider(arg));

    if (wards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppColors.primary.withOpacity(0.4),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'No results found',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SummaryBanner(
              totalTarget: totalTarget,
              totalPatients: totalPatients,
              overallPct: overallPct,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                '${wards.length} ward${wards.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _WardCard(
                  aggregate: wards[index],
                  animController: animController,
                  groupIndex: index,
                ),
                childCount: wards.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — By Facility
// ─────────────────────────────────────────────────────────────────────────────
class _FacilityTab extends ConsumerWidget {
  final DetailArg arg;
  final int totalTarget;
  final int totalPatients;
  final double overallPct;
  final AnimationController animController;
  final Future<void> Function() onRefresh;

  const _FacilityTab({
    required this.arg,
    required this.totalTarget,
    required this.totalPatients,
    required this.overallPct,
    required this.animController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayData = ref.watch(filteredDetailProvider(arg));

    if (displayData.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppColors.primary.withOpacity(0.4),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'No results found',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<FacilityDetailModel>>{};
    for (final item in displayData) {
      grouped.putIfAbsent(item.facilityName, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SummaryBanner(
              totalTarget: totalTarget,
              totalPatients: totalPatients,
              overallPct: overallPct,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                '${grouped.length} facilit${grouped.length != 1 ? 'ies' : 'y'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final entry = grouped.entries.elementAt(index);
                  return FacilityGroup(
                    facilityName: entry.key,
                    categories: entry.value,
                    animController: animController,
                    groupIndex: index,
                  );
                },
                childCount: grouped.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ward Card — aggregate KPI card + expandable facility list
// Uses the same visual language as FacilityGroup for consistency.
// ─────────────────────────────────────────────────────────────────────────────
class _WardCard extends StatefulWidget {
  final WardAggregate aggregate;
  final AnimationController animController;
  final int groupIndex;

  const _WardCard({
    required this.aggregate,
    required this.animController,
    required this.groupIndex,
  });

  @override
  State<_WardCard> createState() => _WardCardState();
}

class _WardCardState extends State<_WardCard> {
  final bool _expanded = false;

  ({Color bg, Color fg}) _badgeStyle(double pct) {
    if (pct >= 100) {
      return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
    }
    if (pct >= 50) {
      return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
    }
    return (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFBE123C));
  }

  Color _barColor(double pct) {
    if (pct >= 100) return const Color(0xFF22C55E);
    if (pct >= 75) return const Color(0xFFF59E0B);
    if (pct >= 50) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _fmt(int v) {
    final a = v.abs();
    if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final agg = widget.aggregate;
    final pct = agg.completionPercent;
    final badge = _badgeStyle(pct);
    final barColor = _barColor(pct);
    final diff = agg.diff;
    final isExceeded = diff >= 0;
    final diffColor = isExceeded
        ? const Color(0xFF16A34A)
        : const Color(0xFFBE123C);

    final delay = (widget.groupIndex * 0.12).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: widget.animController,
      curve: Interval(
        delay,
        (delay + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    // Unique facilities in this ward
    final facilityCount =
        agg.items.map((e) => e.facilityName).toSet().length;

    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
            onTap: () => Get.to(
                  () => WardFacilityDetailScreen(
                wardName: agg.ward,
                wardItems: agg.items,
              ),
              transition: Transition.rightToLeft,
            ),


          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agg.ward,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$facilityCount facilit${facilityCount != 1 ? 'ies' : 'y'}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badge.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: badge.fg,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── KPI Strip ──────────────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border.symmetric(
                      horizontal:
                      BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _kpiCell(
                          label: 'TARGET',
                          value: _fmt(agg.totalTarget),
                          valueColor: const Color(0xFF111827),
                          sub: 'annual goal',
                        ),
                        _verticalDivider(),
                        _kpiCell(
                          label: 'COMPLETED',
                          value: _fmt(agg.totalPatients),
                          valueColor: const Color(0xFF111827),
                          sub: 'actual',
                        ),
                        _verticalDivider(),
                        _kpiCell(
                          label: 'DIFFERENCE',
                          value:
                          '${isExceeded && diff > 0 ? '+' : ''}${_fmt(diff)}',
                          valueColor: diffColor,
                          sub: isExceeded ? 'above target' : 'remaining',
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Progress Bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (pct / 100).clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (ctx, val, _) => LinearProgressIndicator(
                        value: val,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ),
                ),

                // ── Expand / Collapse button ────────────────────────────────────
                InkWell(
                  onTap: () {
                   /* Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WardFacilityDetailScreen(
                          wardName: agg.ward,
                          wardItems: agg.items,
                        ),
                      ),
                    );*/
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _expanded
                              ? 'Hide facilities'
                              : 'Tap to show $facilityCount facilit${facilityCount != 1 ? 'ies' : 'y'} details',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Expandable Facility List ────────────────────────────────────
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: _expanded
                      ? _WardFacilityList(items: agg.items)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpiCell({
    required String label,
    required String value,
    required Color valueColor,
    required String sub,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return const VerticalDivider(
      width: 1,
      thickness: 0.8,
      color: Color(0xFFE5E7EB),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ward Facility List — expanded section inside a WardCard
// Groups the ward's items by facility name, same card as By Facility tab.
// ─────────────────────────────────────────────────────────────────────────────
class _WardFacilityList extends StatelessWidget {
  final List<FacilityDetailModel> items;

  const _WardFacilityList({required this.items});

  @override
  Widget build(BuildContext context) {
    // Group by facility name within this ward
    final grouped = <String, List<FacilityDetailModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.facilityName, () => []).add(item);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) {
          return _ExpandedFacilityGroup(
            facilityName: entry.key,
            categories: entry.value,
          );
        }).toList(),
      ),
    );
  }
}

// A lighter version of FacilityGroup used inside the ward expansion
class _ExpandedFacilityGroup extends StatelessWidget {
  final String facilityName;
  final List<FacilityDetailModel> categories;

  const _ExpandedFacilityGroup({
    required this.facilityName,
    required this.categories,
  });

  ({Color bg, Color fg}) _badgeStyle(double pct) {
    if (pct >= 100) {
      return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
    }
    if (pct >= 50) {
      return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
    }
    return (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFBE123C));
  }

  @override
  Widget build(BuildContext context) {
    final int groupTarget = categories.fold(0, (s, e) => s + e.yearlyTarget);
    final int groupActual = categories.fold(0, (s, e) => s + e.patCount);
    final double groupPct = groupTarget > 0
        ? (groupActual / groupTarget * 100).clamp(0.0, 200.0)
        : 0.0;
    final badge = _badgeStyle(groupPct);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: AppColors.primary,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    facilityName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${groupPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: badge.fg,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              children: categories
                  .map((cat) => _CategoryRow(category: cat))
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Banner
// ─────────────────────────────────────────────────────────────────────────────
class SummaryBanner extends StatelessWidget {
  final int totalTarget;
  final int totalPatients;
  final double overallPct;

  const SummaryBanner({super.key, 
    required this.totalTarget,
    required this.totalPatients,
    required this.overallPct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'Yearly Target',
                  value: _fmt(totalTarget),
                  iconColor: const Color(0xFF6366F1),
                  icon: Icons.flag_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  label: 'Completed',
                  value: _fmt(totalPatients),
                  iconColor: const Color(0xFF10B981),
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Completion',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${overallPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _pctColor(overallPct),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallPct / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(_pctColor(overallPct)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  Color _pctColor(double pct) {
    if (pct >= 75) return const Color(0xFF10B981);
    if (pct >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color iconColor;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Facility Group (By Facility tab — unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class FacilityGroup extends StatelessWidget {
  final String facilityName;
  final List<FacilityDetailModel> categories;
  final AnimationController animController;
  final int groupIndex;

  const FacilityGroup({super.key, 
    required this.facilityName,
    required this.categories,
    required this.animController,
    required this.groupIndex,
  });

  ({Color bg, Color fg}) _badgeStyle(double pct) {
    if (pct >= 100) {
      return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
    }
    if (pct >= 50) {
      return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
    }
    return (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFBE123C));
  }

  @override
  Widget build(BuildContext context) {
    final delay = (groupIndex * 0.12).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: animController,
      curve: Interval(
        delay,
        (delay + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    final int groupTarget = categories.fold(0, (s, e) => s + e.yearlyTarget);
    final int groupActual = categories.fold(0, (s, e) => s + e.patCount);
    final double groupPct = groupTarget > 0
        ? (groupActual / groupTarget * 100).clamp(0.0, 200.0)
        : 0.0;
    final badge = _badgeStyle(groupPct);

    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      facilityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badge.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${groupPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: badge.fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: categories
                    .map((cat) => _CategoryRow(category: cat))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Row (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final FacilityDetailModel category;

  const _CategoryRow({required this.category});

  Color _barColor(double ratio) {
    if (ratio >= 1.0) return const Color(0xFF22C55E);
    if (ratio >= 0.75) return const Color(0xFFF59E0B);
    if (ratio >= 0.50) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  ({Color bg, Color fg}) _badgeStyle(double pct) {
    if (pct >= 100) {
      return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
    }
    if (pct >= 50) {
      return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
    }
    return (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFBE123C));
  }

  String _fmt(int n) {
    final a = n.abs();
    if (a >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (a >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pct = category.completionPercent;
    final ratio = category.yearlyTarget > 0
        ? category.patCount / category.yearlyTarget
        : (category.patCount > 0 ? 1.0 : 0.0);

    final barColor = _barColor(ratio);
    final badge = _badgeStyle(pct);
    final isOverAchieved =
        category.yearlyTarget <= 0 && category.patCount > 0;

    final int diff = category.patCount - category.yearlyTarget;
    final bool isExceeded = diff >= 0;
    final Color diffColor = isExceeded
        ? const Color(0xFF16A34A)
        : const Color(0xFFBE123C);

    final badgeColor = switch (category.mobCatCode) {
      1 => const Color(0xFF6366F1),
      2 => const Color(0xFF0EA5E9),
      3 => const Color(0xFFF59E0B),
      _ => AppColors.primary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.catName,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: badge.fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border.symmetric(
                horizontal:
                BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _kpiCell(
                    label: 'TARGET',
                    value: _fmt(category.yearlyTarget),
                    valueColor: const Color(0xFF111827),
                    sub: 'annual goal',
                  ),
                  _verticalDivider(),
                  _kpiCell(
                    label: 'COMPLETED',
                    value: _fmt(category.patCount),
                    valueColor: const Color(0xFF111827),
                    sub: 'actual',
                  ),
                  _verticalDivider(),
                  _kpiCell(
                    label: 'DIFFERENCE',
                    value:
                    '${isExceeded && diff > 0 ? '+' : ''}${_fmt(diff)}',
                    valueColor: diffColor,
                    sub: isExceeded ? 'above target' : 'remaining',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: isOverAchieved
                ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 13,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Exceeds target',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct / 100),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (ctx, val, _) => LinearProgressIndicator(
                  value: val,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCell({
    required String label,
    required String value,
    required Color valueColor,
    required String sub,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return const VerticalDivider(
      width: 1,
      thickness: 0.8,
      color: Color(0xFFE5E7EB),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFF94A3B8),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}/*
class FacilityDetailScreen extends ConsumerStatefulWidget {
  final int fTypeId;
  final String facilityName;

  const FacilityDetailScreen({
    super.key,
    required this.fTypeId,
    required this.facilityName,
  });

  @override
  ConsumerState<FacilityDetailScreen> createState() =>
      _FacilityDetailScreenState();
}*/

// class _FacilityDetailScreenState extends ConsumerState<FacilityDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _animController;
//   final TextEditingController _searchCtrl = TextEditingController();
//   final FocusNode _searchFocus = FocusNode();
//   bool _searchOpen = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     )..forward();
//   }
//
//   @override
//   void dispose() {
//     _animController.dispose();
//     _searchCtrl.dispose();
//     _searchFocus.dispose();
//     super.dispose();
//   }
//
//   void _toggleSearch() {
//     setState(() => _searchOpen = !_searchOpen);
//     if (_searchOpen) {
//       Future.microtask(() => _searchFocus.requestFocus());
//     } else {
//       _searchCtrl.clear();
//       ref.read(detailSearchQueryProvider.notifier).state = '';
//       _searchFocus.unfocus();
//     }
//   }
//
//   DetailArg _arg(int yearId) =>
//       DetailArg(fTypeId: widget.fTypeId, yearId: yearId);
//
//   @override
//   Widget build(BuildContext context) {
//     final selectedYear = ref.watch(selectedYearProvider);
//     final arg = _arg(selectedYear);
//     final detailState = ref.watch(facilityDetailProvider(arg));
//     final yearsAsync = ref.watch(financialYearsProvider);
//     final sortOption = ref.watch(detailSortOptionProvider);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F5F9),
//       body: NestedScrollView(
//         headerSliverBuilder: (ctx, _) => [
//           _buildAppBar(
//             yearsAsync: yearsAsync,
//             selectedYear: selectedYear,
//             isLoading: detailState.isLoading,
//             sortOption: sortOption,
//           ),
//         ],
//         body: _buildBody(detailState, arg),
//       ),
//     );
//   }
//
//   // ── Sliver App Bar ──────────────────────────────────────────────────────────
//   Widget _buildAppBar({
//     required AsyncValue<List<ProjectFinancialYear>> yearsAsync,
//     required int selectedYear,
//     required bool isLoading,
//     required SortOption sortOption,
//   }) {
//     return SliverAppBar(
//       expandedHeight: 140,
//       floating: false,
//       pinned: true,
//       backgroundColor: AppColors.primary,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(25),
//           bottomRight: Radius.circular(25),
//         ),
//       ),
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(
//           Icons.arrow_back_ios_new_rounded,
//           color: Colors.white,
//           size: 18,
//         ),
//         onPressed: () => Navigator.pop(context),
//       ),
//       leadingWidth: 30,
//       // ── Collapsed bar: title + sort button ──────────────────────────────────
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'Facility Type',
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 11,
//               fontWeight: FontWeight.w500,
//               letterSpacing: 0.5,
//             ),
//           ),
//           Text(
//             widget.facilityName,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 15,
//               fontWeight: FontWeight.w900,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//       actions: [
//         // Sort button visible in collapsed state (always in actions)
//         SortButton(
//           selected: sortOption,
//           onSelected: (opt) =>
//               ref.read(detailSortOptionProvider.notifier).state = opt,
//         ),
//         const SizedBox(width: 8),
//       ],
//       // ── Expanded area: year chips + search ────────────────────────────────
//       flexibleSpace: FlexibleSpaceBar(
//         background: Container(
//           decoration: const BoxDecoration(
//             borderRadius: BorderRadius.only(
//               bottomLeft: Radius.circular(25),
//               bottomRight: Radius.circular(25),
//             ),
//             gradient: AppColors.primaryGradient,
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 58, 16, 12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   const Text(
//                     'Project Year',
//                     style: TextStyle(
//                       color: Colors.white60,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                       letterSpacing: 0.4,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   // ── Year row with inline search ───────────────────────────
//                   YearRowWithSearch(
//                     yearsAsync: yearsAsync,
//                     selectedYear: selectedYear,
//                     searchOpen: _searchOpen,
//                     searchCtrl: _searchCtrl,
//                     searchFocus: _searchFocus,
//                     onSearchChanged: (v) =>
//                     ref.read(detailSearchQueryProvider.notifier).state = v,
//                     onToggleSearch: _toggleSearch,
//                     onYearSelected: (yearId) => // ✅ updates shared provider → both screens react
//                     ref.read(selectedYearProvider.notifier).state = yearId,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ── Body ────────────────────────────────────────────────────────────────────
//   Widget _buildBody(FacilityDetailState state, DetailArg arg) {
//     if (state.isLoading) return const ConsumptionSkeleton();
//
//     if (state.error != null) {
//       return _ErrorView(
//         message: state.error!,
//         onRetry: () => ref.read(facilityDetailProvider(arg).notifier).refresh(),
//       );
//     }
//
//     if (state.data.isEmpty) {
//       return const Center(
//         child: Text(
//           'No data available',
//           style: TextStyle(color: AppColors.primary),
//         ),
//       );
//     }
//
//     // ── Use the derived (filtered + sorted) list ──────────────────────────────
//     final displayData = ref.watch(filteredDetailProvider(arg));
//
//     if (displayData.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.search_off_rounded,
//               color: AppColors.primary.withOpacity(0.4),
//               size: 48,
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'No results found',
//               style: TextStyle(
//                 color: AppColors.primary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     final grouped = <String, List<FacilityDetailModel>>{};
//     for (final item in displayData) {
//       grouped.putIfAbsent(item.facilityName, () => []).add(item);
//     }
//
//     final totalTarget = displayData.fold(0, (s, e) => s + e.yearlyTarget);
//     final totalPatients = displayData.fold(0, (s, e) => s + e.patCount);
//     final overallPct = totalTarget > 0
//         ? (totalPatients / totalTarget * 100).clamp(0.0, 100.0)
//         : 0.0;
//
//     return RefreshIndicator(
//       onRefresh: () => ref.read(facilityDetailProvider(arg).notifier).refresh(),
//       color: AppColors.primary,
//       child: CustomScrollView(
//         slivers: [
//           SliverToBoxAdapter(
//             child: _SummaryBanner(
//               totalTarget: totalTarget,
//               totalPatients: totalPatients,
//               overallPct: overallPct.toDouble(),
//             ),
//           ),
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
//               child: Text(
//                 '${grouped.length} facilit${grouped.length != 1 ? 'ies' : 'y'}  '
//                 ,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//             ),
//           ),
//           SliverPadding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             sliver: SliverList(
//               delegate: SliverChildBuilderDelegate((context, index) {
//                 final entry = grouped.entries.elementAt(index);
//                 return FacilityGroup(
//                   facilityName: entry.key,
//                   categories: entry.value,
//                   animController: _animController,
//                   groupIndex: index,
//                 );
//               }, childCount: grouped.length),
//             ),
//           ),
//           const SliverToBoxAdapter(child: SizedBox(height: 32)),
//         ],
//       ),
//     );
//   }
// }
// // ─────────────────────────────────────────────────────────────────────────────
// // Summary Banner
// // ─────────────────────────────────────────────────────────────────────────────
// class _SummaryBanner extends StatelessWidget {
//   final int totalTarget;
//   final int totalPatients; // Kept variable name but changed display label
//   final double overallPct;
//
//   const _SummaryBanner({
//     required this.totalTarget,
//     required this.totalPatients,
//     required this.overallPct,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.08),
//             blurRadius: 16,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: _StatPill(
//                   label: 'Yearly Target',
//                   value: _fmt(totalTarget),
//                   iconColor: const Color(0xFF6366F1),
//                   icon: Icons.flag_rounded,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _StatPill(
//                   label: 'Completed', // Replaced "Patients Served"
//                   value: _fmt(totalPatients),
//                   iconColor: const Color(0xFF10B981),
//                   icon: Icons.check_circle_rounded,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Overall Completion',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primary,
//                 ),
//               ),
//               Text(
//                 '${overallPct.toStringAsFixed(1)}%',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   color: _pctColor(overallPct),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: LinearProgressIndicator(
//               value: overallPct / 100,
//               minHeight: 8,
//               backgroundColor: const Color(0xFFE2E8F0),
//               valueColor: AlwaysStoppedAnimation(_pctColor(overallPct)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _fmt(int v) {
//     if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
//     if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
//     return v.toString();
//   }
//
//   Color _pctColor(double pct) {
//     if (pct >= 75) return const Color(0xFF10B981);
//     if (pct >= 40) return const Color(0xFFF59E0B);
//     return const Color(0xFFEF4444);
//   }
// }
//
// class _StatPill extends StatelessWidget {
//   final String label;
//   final String value;
//   final Color iconColor;
//   final IconData icon;
//
//   const _StatPill({
//     required this.label,
//     required this.value,
//     required this.iconColor,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: iconColor.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(7),
//             decoration: BoxDecoration(
//               color: iconColor.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: iconColor, size: 16),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                     color: Color(0xFF1E293B),
//                   ),
//                 ),
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: AppColors.primary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Facility Group
// // ─────────────────────────────────────────────────────────────────────────────
// class FacilityGroup extends StatelessWidget {
//   final String facilityName;
//   final List<FacilityDetailModel> categories;
//   final AnimationController animController;
//   final int groupIndex;
//
//   const FacilityGroup({
//     required this.facilityName,
//     required this.categories,
//     required this.animController,
//     required this.groupIndex,
//   });
//
//   ({Color bg, Color fg}) _badgeStyle(double pct) {
//     if (pct >= 100) return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
//     if (pct >= 50)  return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
//     return          (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFBE123C));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final delay = (groupIndex * 0.12).clamp(0.0, 0.6);
//     final animation = CurvedAnimation(
//       parent: animController,
//       curve: Interval(
//         delay,
//         (delay + 0.4).clamp(0.0, 1.0),
//         curve: Curves.easeOutCubic,
//       ),
//     );
//
//     // Calculate group overall percentage
//     final int groupTarget = categories.fold(0, (s, e) => s + e.yearlyTarget);
//     final int groupActual = categories.fold(0, (s, e) => s + e.patCount);
//     final double groupPct = groupTarget > 0 ? (groupActual / groupTarget * 100).clamp(0.0, 200.0) : 0.0;
//     final badge = _badgeStyle(groupPct);
//
//     return AnimatedBuilder(
//       animation: animation,
//       builder: (ctx, child) => Opacity(
//         opacity: animation.value,
//         child: Transform.translate(
//           offset: Offset(0, 20 * (1 - animation.value)),
//           child: child,
//         ),
//       ),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 12,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
//               decoration: const BoxDecoration(
//                 gradient: AppColors.primaryGradient,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Icon(
//                       Icons.local_hospital_rounded,
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       facilityName,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                   // Resolved TODO: Replaced count with the percentage badge styling
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: badge.bg,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       '${groupPct.toStringAsFixed(1)}%',
//                       style: TextStyle(
//                         color: badge.fg,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w700,
//                         fontFeatures: const [FontFeature.tabularFigures()],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//               child: Column(
//                 children: categories
//                     .map((cat) => _CategoryRow(category: cat))
//                     .toList(),
//               ),
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Category Row (Revamped with KPI Strip)
// // ─────────────────────────────────────────────────────────────────────────────
// class _CategoryRow extends StatelessWidget {
//   final FacilityDetailModel category;
//
//   const _CategoryRow({required this.category});
//
//   Color _barColor(double ratio) {
//     if (ratio >= 1.0)  return const Color(0xFF22C55E); // green  — exceeded
//     if (ratio >= 0.75) return const Color(0xFFF59E0B); // amber  — close
//     if (ratio >= 0.50) return const Color(0xFFF97316); // orange — mid
//     return const Color(0xFFEF4444);                    // red    — low
//   }
//
//   ({Color bg, Color fg}) _badgeStyle(double pct) {
//     if (pct >= 100) return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
//     if (pct >= 50)  return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
//     return          (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFBE123C));
//   }
//
//   String _fmt(int n) {
//     final a = n.abs();
//     if (a >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
//     if (a >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
//     return n.toString();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final pct = category.completionPercent;
//     final ratio = category.yearlyTarget > 0
//         ? category.patCount / category.yearlyTarget
//         : (category.patCount > 0 ? 1.0 : 0.0);
//
//     final barColor = _barColor(ratio);
//     final badge = _badgeStyle(pct);
//     final isOverAchieved = category.yearlyTarget <= 0 && category.patCount > 0;
//
//     // Calculate difference based on target
//     final int diff = category.patCount - category.yearlyTarget;
//     final bool isExceeded = diff >= 0;
//     final Color diffColor = isExceeded ? const Color(0xFF16A34A) : const Color(0xFFBE123C);
//
//     final badgeColor = switch (category.mobCatCode) {
//       1 => const Color(0xFF6366F1),
//       2 => const Color(0xFF0EA5E9),
//       3 => const Color(0xFFF59E0B),
//       _ => AppColors.primary,
//     };
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.02),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header Row
//           Padding(
//             padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                   decoration: BoxDecoration(
//                     color: badgeColor.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     category.catName,
//                     style: TextStyle(
//                       color: badgeColor,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 // Resolved TODO: Show percentage here
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: badge.bg,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     '${pct.toStringAsFixed(1)}%',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       fontFeatures: const [FontFeature.tabularFigures()],
//                       color: badge.fg,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // KPI Strip (Replacing `_MiniStat`)
//           Container(
//             decoration: const BoxDecoration(
//               color: Color(0xFFF9FAFB),
//               border: Border.symmetric(
//                 horizontal: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
//               ),
//             ),
//             child: IntrinsicHeight(
//               child: Row(
//                 children: [
//                   _kpiCell(
//                     label: 'TARGET',
//                     value: _fmt(category.yearlyTarget),
//                     valueColor: const Color(0xFF111827),
//                     sub: 'annual goal',
//                   ),
//                   _verticalDivider(),
//                   _kpiCell(
//                     label: 'COMPLETED',
//                     value: _fmt(category.patCount),
//                     valueColor: const Color(0xFF111827),
//                     sub: 'actual',
//                   ),
//                   _verticalDivider(),
//                   // Resolved TODO: Show difference here
//                   _kpiCell(
//                     label: 'DIFFERENCE',
//                     value: '${isExceeded && diff > 0 ? '+' : ''}${_fmt(diff)}',
//                     valueColor: diffColor,
//                     sub: isExceeded ? 'above target' : 'remaining',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Progress Bar with Zones
//           Padding(
//             padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
//             child: isOverAchieved
//                 ? Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF10B981).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.check_circle_rounded,
//                     color: Color(0xFF10B981),
//                     size: 13,
//                   ),
//                   SizedBox(width: 4),
//                   Text(
//                     'Exceeds target',
//                     style: TextStyle(
//                       color: Color(0xFF10B981),
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//             // Resolved TODO: Progress bar with reference zone logic
//                 : ClipRRect(
//               borderRadius: BorderRadius.circular(6),
//               child: TweenAnimationBuilder<double>(
//                 tween: Tween(begin: 0, end: pct / 100),
//                 duration: const Duration(milliseconds: 800),
//                 curve: Curves.easeOutCubic,
//                 builder: (ctx, val, _) => LinearProgressIndicator(
//                   value: val,
//                   minHeight: 6,
//                   backgroundColor: const Color(0xFFE2E8F0),
//                   valueColor: AlwaysStoppedAnimation(barColor),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Local helper widgets for the KPI Strip
//   Widget _kpiCell({
//     required String label,
//     required String value,
//     required Color valueColor,
//     required String sub,
//   }) {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 9,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF6B7280),
//                 letterSpacing: 0.5,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w800,
//                 color: valueColor,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               sub,
//               style: const TextStyle(
//                 fontSize: 9,
//                 color: Color(0xFF9CA3AF),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _verticalDivider() {
//     return const VerticalDivider(
//       width: 1,
//       thickness: 0.8,
//       color: Color(0xFFE5E7EB),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────*/
// // Skeleton
// // ─────────────────────────────────────────────────────────────────────────────
//
//
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Error View
// // ─────────────────────────────────────────────────────────────────────────────
// class _ErrorView extends StatelessWidget {
//   final String message;
//   final VoidCallback onRetry;
//
//   const _ErrorView({required this.message, required this.onRetry});
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.wifi_off_rounded,
//               color: Color(0xFF94A3B8),
//               size: 48,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: AppColors.primary, fontSize: 13),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: onRetry,
//               icon: const Icon(Icons.refresh_rounded, size: 16),
//               label: const Text('Retry'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
