import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';

import 'dart:ui';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Object title;
  final bool showBackButton;
  final bool showDrawerButton;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? titleColor;
  final double elevation;
  final VoidCallback? onBackPressed;
  final VoidCallback? onDrawerPressed;
  final bool centerTitle;
  final Widget? flexibleSpace;

  // ── Search API ──────────────────────────────────────────────────
  final bool enableSearch;
  final String searchHint;
  final TextEditingController? searchController; // avoid passing this — see note below
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onSearchOpened;
  final VoidCallback? onSearchClosed;
  final VoidCallback? onSearchCleared;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showDrawerButton = false,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.titleColor,
    this.elevation = 4.0,
    this.onBackPressed,
    this.onDrawerPressed,
    this.centerTitle = true,
    this.flexibleSpace,
    this.enableSearch = false,
    this.searchHint = 'Search...',
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchOpened,
    this.onSearchClosed,
    this.onSearchCleared,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSearchMode = false;
  bool _ownsController = false;
  bool _hasText = false;
  bool _disposed = false; // guards against use-after-dispose during route teardown

  @override
  void initState() {
    super.initState();
    if (widget.searchController != null) {
      _controller = widget.searchController!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted || _disposed) return;
    widget.onSearchChanged?.call(_controller.text);
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _openSearch() {
    if (_disposed) return;
    setState(() => _isSearchMode = true);
    widget.onSearchOpened?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      _focusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (_disposed) return;
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
    if (_disposed) return;
    _controller.clear();
    widget.onSearchCleared?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: _buildLeading(context, theme),
      title: _buildTitleArea(context),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      elevation: 4,
      leadingWidth: _isSearchMode ? 48 : 34,
      actions: _buildActions(),
    );
  }

  // ── Title / Search swap ─────────────────────────────────────────
  Widget _buildTitleArea(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            axis: Axis.horizontal,
            axisAlignment: -1,
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: _isSearchMode
          ? _buildGlassSearchField(key: const ValueKey('search'))
          : _buildTitle(context, key: const ValueKey('title')),
    );
  }

  Widget _buildTitle(BuildContext context, {Key? key}) {
    if (widget.title is Widget) {
      return KeyedSubtree(key: key, child: widget.title as Widget);
    }
    return Text(
      key: key,
      widget.title as String,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: widget.titleColor ?? Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  // ── Liquid-glass search field ────────────────────────────────────
  Widget _buildGlassSearchField({Key? key}) {
    return Container(
      key: key,
      height: 40,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
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
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(0.75),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    cursorColor: Colors.white,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      isCollapsed: true,
                      hintText: widget.searchHint,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    onSubmitted: (value) {
                      widget.onSearchSubmitted?.call(value);
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: _hasText
                      ? IconButton(
                    key: const ValueKey('clear'),
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: _clearSearch,
                    tooltip: 'Clear',
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

  // ── Leading ─────────────────────────────────────────────────────
  Widget? _buildLeading(BuildContext context, ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: _resolveLeading(context, theme),
    );
  }

  Widget? _resolveLeading(BuildContext context, ThemeData theme) {
    if (_isSearchMode) {
      return IconButton(
        key: const ValueKey('close'),
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
        onPressed: _closeSearch,
        tooltip: 'Close search',
      );
    }

    if (widget.leading != null) {
      return KeyedSubtree(key: const ValueKey('custom'), child: widget.leading!);
    }

    if (widget.showBackButton) {
      return IconButton(
        key: const ValueKey('back'),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: widget.titleColor ?? theme.colorScheme.onPrimary,
        ),
        onPressed: widget.onBackPressed ?? () => Get.back(),
      );
    }

    if (widget.showDrawerButton) {
      return IconButton(
        key: const ValueKey('drawer'),
        icon: Icon(
          Icons.menu,
          color: widget.titleColor ?? theme.colorScheme.onPrimary,
        ),
        onPressed: widget.onDrawerPressed ?? () => Scaffold.of(context).openDrawer(),
      );
    }

    return const SizedBox.shrink(key: ValueKey('none'));
  }

  // ── Actions ─────────────────────────────────────────────────────
  List<Widget> _buildActions() {
    return [
      if (widget.actions != null) ...widget.actions!,
      if (widget.enableSearch && !_isSearchMode)
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: _openSearch,
          tooltip: 'Search',
        ),
    ];
  }
}

/*class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Object title;
  final bool showBackButton;
  final bool showDrawerButton; // New property
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? titleColor;
  final double elevation;
  final VoidCallback? onBackPressed;
  final VoidCallback? onDrawerPressed; // New property
  final bool centerTitle;
  final Widget? flexibleSpace;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showDrawerButton = false, // Default to false
    this.actions,
    this.leading,
    this.backgroundColor,
    this.titleColor ,
    this.elevation = 4.0,
    this.onBackPressed,
    this.onDrawerPressed, // Initialize
    this.centerTitle = true,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppBar(
      leading: _buildLeading(context, theme),
        title: buildTitle(context),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        elevation: 4,
        leadingWidth: 34,
        actions:
        [ if (actions != null) ...actions!,]


    );
  }
  Widget buildTitle(BuildContext context){
    if (title is Widget){
      return title as Widget;
    }
   return Text(
      title as String,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: titleColor ?? Theme.of(context).colorScheme.onPrimary,
      ),
    );

  }


  Widget? _buildLeading(BuildContext context, ThemeData theme) {
    if (leading != null) return leading;

    if (showBackButton) {
      return IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: titleColor ?? theme.colorScheme.onPrimary),
          onPressed: onBackPressed ?? () => Get.back(),
      );
    }

    if (showDrawerButton) {
      return IconButton(
        icon:
        Icon(Icons.menu, color: titleColor ?? theme.colorScheme.onPrimary),
        onPressed: onDrawerPressed ?? () => Scaffold.of(context).openDrawer(),
      );
    }

    return null;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}*/
