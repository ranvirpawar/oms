// lib/features/phlebotomist/patient_queue/view/widgets/patient_queue_scroll_header.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart' hide SnackPosition;
import '../../../../../theme/app_colors.dart';

/// Replicates CustomAppBar's visuals (gradient, rounded bottom corners,
/// leading/back button, animated title↔search swap, actions) as a plain
/// widget instead of a real Material `AppBar` — so its height is exactly
/// what we say it is, with no hidden safe-area padding surprises. Sits in a
/// [SliverPersistentHeader] with floating+snap physics so it hides on
/// scroll-down and reappears on scroll-up, HIG-eased.
class PatientQueueScrollHeader extends StatefulWidget {
  const PatientQueueScrollHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.enableSearch = false,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchOpened,
    this.onSearchClosed,
    this.onSearchCleared,
    this.filterBar,
    this.filterBarHeight = 56,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  final bool enableSearch;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onSearchOpened;
  final VoidCallback? onSearchClosed;
  final VoidCallback? onSearchCleared;

  final Widget? filterBar;
  final double filterBarHeight;

  /// Total sliver extent this header needs, given the current context's
  /// top padding. Compute this once at the call site and pass it into the
  /// SliverPersistentHeaderDelegate as both min/maxExtent.
  static double totalHeight(BuildContext context, {required double filterBarHeight}) {
    final topPadding = MediaQuery.of(context).padding.top;
    return topPadding + kToolbarHeight + filterBarHeight;
  }

  @override
  State<PatientQueueScrollHeader> createState() => _PatientQueueScrollHeaderState();
}

class _PatientQueueScrollHeaderState extends State<PatientQueueScrollHeader> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSearchMode = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onSearchChanged?.call(_controller.text);
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _openSearch() {
    setState(() => _isSearchMode = true);
    widget.onSearchOpened?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _controller.clear();
    widget.onSearchCleared?.call();
    setState(() {
      _isSearchMode = false;
      _hasText = false;
    });
    _focusNode.unfocus();
    widget.onSearchClosed?.call();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchCleared?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // clipBehavior: Clip.hardEdge,
        children: [
          Container(
            height: topPadding + kToolbarHeight,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(

                  children: [
                    const SizedBox(width: 4),
                    _buildLeading(),
                    SizedBox(width: _isSearchMode ? 0 : 12),
                    Expanded(child: _buildTitleArea()),
                    ..._buildActions(),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
          if (widget.filterBar != null)
            SizedBox(height: widget.filterBarHeight, child: widget.filterBar),
        ],
      ),
    );
  }

  Widget _buildTitleArea() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          axis: Axis.horizontal,
          axisAlignment: -1,
          sizeFactor: animation,
          child: child,
        ),
      ),
      child: _isSearchMode
          ? _buildGlassSearchField(key: const ValueKey('search'))
          : Text(
        key: const ValueKey('title'),
        widget.title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGlassSearchField({Key? key}) {
    return Container(
      key: key,
      height: 40,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.16),
              border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.10), Colors.white.withOpacity(0.02)],
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded, size: 18, color: Colors.white.withOpacity(0.75)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    cursorColor: Colors.white,
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      filled: false,
                      isCollapsed: true,
                      hintText: widget.searchHint,
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    onSubmitted: widget.onSearchSubmitted,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                  child: _hasText
                      ? IconButton(
                    key: const ValueKey('clear'),
                    icon: Icon(Icons.clear_rounded, size: 18, color: Colors.white.withOpacity(0.85)),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _clearSearch,
                  )
                      : const SizedBox(width: 4, key: ValueKey('empty')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
      child: SizedBox(
        width: _isSearchMode ? 48 : 34,
        child: _isSearchMode
            ? IconButton(
          key: const ValueKey('close'),
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          onPressed: _closeSearch,
        )
            : (widget.showBackButton
            ? IconButton(
          key: const ValueKey('back'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: widget.onBackPressed ?? () => Get.back(),
        )
            : const SizedBox.shrink(key: ValueKey('none'))),
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      if (widget.actions != null) ...widget.actions!,
      if (widget.enableSearch && !_isSearchMode)
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: _openSearch,
        ),
    ];
  }
}

/// Fixed-extent delegate so the header behaves as one solid floating block —
/// state (search mode, text) lives in [PatientQueueScrollHeader]'s own State
/// and survives rebuilds since it's the same widget type at the same slot.
class PatientQueueHeaderDelegate extends SliverPersistentHeaderDelegate {
  PatientQueueHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  FloatingHeaderSnapConfiguration? get snapConfiguration =>  FloatingHeaderSnapConfiguration(
    curve: Curves.easeOutCubic,
    duration: Duration(milliseconds: 280),
  );

  @override
  bool shouldRebuild(covariant PatientQueueHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}