import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';

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
  final TextEditingController? searchController; // optional – owns one if null
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
    // Search
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
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    widget.onSearchChanged?.call(_controller.text);
    // Rebuild so clear button appears/disappears
    setState(() {});
  }

  void _openSearch() {
    setState(() => _isSearchMode = true);
    widget.onSearchOpened?.call();
    // Wait one frame so the TextField is in the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _controller.clear();
    widget.onSearchCleared?.call();
    setState(() => _isSearchMode = false);
    _focusNode.unfocus();
    widget.onSearchClosed?.call();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: _buildLeading(context, theme),
      title: _isSearchMode ? _buildSearchField() : _buildTitle(context),
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
      actions: _isSearchMode ? _buildSearchActions() : _buildNormalActions(),
    );
  }

  // ── Title ───────────────────────────────────────────────────────
  Widget _buildTitle(BuildContext context) {
    if (widget.title is Widget) return widget.title as Widget;
    return Text(
      widget.title as String,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: widget.titleColor ?? Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  // ── Search Field ────────────────────────────────────────────────
  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: widget.searchHint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.75),
          fontSize: 15,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onSubmitted: (value) {
        widget.onSearchSubmitted?.call(value);
        _focusNode.unfocus();
      },
    );
  }

  // ── Leading ─────────────────────────────────────────────────────
  Widget? _buildLeading(BuildContext context, ThemeData theme) {
    if (_isSearchMode) {
      return IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
        onPressed: _closeSearch,
        tooltip: 'Close search',
      );
    }

    if (widget.leading != null) return widget.leading;

    if (widget.showBackButton) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: widget.titleColor ?? theme.colorScheme.onPrimary,
        ),
        onPressed: widget.onBackPressed ?? () => Get.back(),
      );
    }

    if (widget.showDrawerButton) {
      return IconButton(
        icon: Icon(
          Icons.menu,
          color: widget.titleColor ?? theme.colorScheme.onPrimary,
        ),
        onPressed: widget.onDrawerPressed ?? () => Scaffold.of(context).openDrawer(),
      );
    }

    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────
  List<Widget> _buildNormalActions() {
    return [
      if (widget.actions != null) ...widget.actions!,
      if (widget.enableSearch)
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: _openSearch,
          tooltip: 'Search',
        ),
    ];
  }

  List<Widget> _buildSearchActions() {
    if (_controller.text.isEmpty) return const [];
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded, color: Colors.white, size: 20),
        onPressed: _clearSearch,
        tooltip: 'Clear',
      ),
    ];
  }
}/*class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
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


