import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
class ModernDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?)? onChanged;
  final String? iconPath;
  final bool isRequired;
  final bool isReadOnly;
  final TextStyle? labelStyle;
  final TextStyle? itemStyle;
  final TextStyle? selectedItemStyle;
  final Color? backgroundColor;
  final Color? dropdownBackgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final EdgeInsets? padding;
  final double borderRadius;
  final double iconSize;
  final Widget Function(String)? customItemBuilder;

  // Multiple selection properties
  final bool isMultiSelect;
  final List<String>? selectedValues;
  final Function(List<String>)? onMultiSelectionChanged;
  final String? multiSelectSeparator;
  final int? maxDisplayItems;

  // Search functionality
  final bool enableSearch;
  final String? searchHint;
  final String? placeholder;

  const ModernDropdown({
    super.key,
    required this.label,
     this.value,
    required this.items,
    required this.onChanged,
    this.iconPath,
    this.isRequired = true,
    this.isReadOnly = false,
    this.labelStyle,
    this.itemStyle,
    this.selectedItemStyle,
    this.backgroundColor,
    this.dropdownBackgroundColor,
    this.borderColor,
    this.iconColor,
    this.padding,
    this.borderRadius = 8.0,
    this.iconSize = 24.0,
    this.customItemBuilder,
    this.isMultiSelect = false,
    this.selectedValues,
    this.onMultiSelectionChanged,
    this.multiSelectSeparator = ', ',
    this.maxDisplayItems = 3,
    this.enableSearch = false,
    this.searchHint = 'Search...',
    this.placeholder,
  })  : assert(
  !isMultiSelect ||
      (selectedValues != null && onMultiSelectionChanged != null),
  'For multi-select mode, selectedValues and onMultiSelectionChanged must be provided',
  ),
        assert(
        isMultiSelect || onChanged != null,
        'For single-select mode, onChanged must be provided',
        );

  // New constructor for multiple selection
  const ModernDropdown.multiSelect({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValues,
    required this.onMultiSelectionChanged,
    this.iconPath,
    this.isRequired = true,
    this.isReadOnly = false,
    this.labelStyle,
    this.itemStyle,
    this.selectedItemStyle,
    this.backgroundColor,
    this.dropdownBackgroundColor,
    this.borderColor,
    this.iconColor,
    this.padding,
    this.borderRadius = 8.0,
    this.iconSize = 24.0,
    this.customItemBuilder,
    this.multiSelectSeparator = ', ',
    this.maxDisplayItems = 3,
    this.enableSearch = false,
    this.searchHint = 'Search...',
    this.placeholder
  })  : isMultiSelect = true,
        value = '',
        onChanged = null;

  @override
  State<ModernDropdown> createState() => _ModernDropdownState();
}

class _ModernDropdownState extends State<ModernDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeDropdown();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredItems = widget.items.where((item) {
        return item.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
    // Rebuild overlay to show filtered results
    if (_overlayEntry != null && mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredItems = widget.items;
    });
  }

  void _toggleDropdown() {
    if (widget.isReadOnly || widget.items.isEmpty) return;
    if (_isOpen) {
      _removeDropdown();
    } else {
      _createDropdown();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _removeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _createDropdown() {
    _clearSearch(); // Reset search when opening
    _filteredItems = widget.items;
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);


    // Focus search field if enabled
    if (widget.enableSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  void _closeDropdown() {
    if (_isOpen) {
      _removeDropdown();
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    }
  }

  void _handleItemTap(String item) {
    if (widget.isMultiSelect) {
      final List<String> currentSelection = List.from(widget.selectedValues ?? []);

      if (currentSelection.contains(item)) {
        currentSelection.remove(item);
      } else {
        currentSelection.add(item);
      }

      widget.onMultiSelectionChanged!(currentSelection);
      // Force the OverlayEntry to rebuild to update tick marks
      if (_overlayEntry != null && mounted) {
        _overlayEntry!.markNeedsBuild();
      }
    } else {
      widget.onChanged?.call(item);
      _closeDropdown();
    }
  }

  bool _isItemSelected(String item) {
    if (widget.isMultiSelect) {
      return widget.selectedValues?.contains(item) ?? false;
    }
    return item == widget.value;
  }

  /*String _getDisplayText() {
    if (widget.isMultiSelect) {
      final selected = widget.selectedValues ?? [];
      if (selected.isEmpty) {
        return 'Select items...';
      }

      if (selected.length <= (widget.maxDisplayItems ?? 3)) {
        return selected.join(widget.multiSelectSeparator ?? ', ');
      } else {
        final displayItems =
        selected.take(widget.maxDisplayItems ?? 3).toList();
        final remaining = selected.length - displayItems.length;
        return '${displayItems.join(widget.multiSelectSeparator ?? ', ')} (+$remaining more)';
      }
    }
    return widget.value;
  }*/

  Widget _buildHighlightedText(String item) {
    if (_searchQuery.isEmpty || !widget.enableSearch) {
      final isSelected = _isItemSelected(item);
      return Text(
        item,
        style: widget.itemStyle ??
            TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black87,
            ),
      );
    }

    final isSelected = _isItemSelected(item);
    final defaultStyle = widget.itemStyle ??
        TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.black87,
        );

    final highlightStyle = defaultStyle.copyWith(
      backgroundColor: Colors.yellow[200],
      fontWeight: FontWeight.bold,
    );

    final text = item.toLowerCase();
    final query = _searchQuery.toLowerCase();
    final matches = <TextSpan>[];

    int start = 0;
    int index = text.indexOf(query, start);

    while (index != -1) {
      if (index > start) {
        matches.add(TextSpan(
          text: item.substring(start, index),
          style: defaultStyle,
        ));
      }
      matches.add(TextSpan(
        text: item.substring(index, index + query.length),
        style: highlightStyle,
      ));
      start = index + query.length;
      index = text.indexOf(query, start);
    }

    if (start < item.length) {
      matches.add(TextSpan(
        text: item.substring(start),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: matches),
    );
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final availableHeightBelow =
        MediaQuery.of(context).size.height - offset.dy - size.height;
    final maxDropdownHeight = MediaQuery.of(context).size.height * 0.3;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    // Determine if dropdown should open upwards or downwards
    final bool shouldOpenUpwards = availableHeightBelow < maxDropdownHeight &&
        offset.dy > maxDropdownHeight;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _closeDropdown(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(
                  0.0,
                  shouldOpenUpwards ? -maxDropdownHeight : size.height,
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    color: widget.dropdownBackgroundColor ??
                        Theme.of(context).cardColor,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: maxDropdownHeight,
                        minHeight: 50,
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.enableSearch) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 4.0),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: widget.searchHint ?? 'Search...',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 18,
                                    color: Colors.grey[500],
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Colors.grey[500],
                                    ),
                                    onPressed: () {
                                      _clearSearch();
                                      if (_overlayEntry != null &&
                                          mounted) {
                                        _overlayEntry!.markNeedsBuild();
                                      }
                                    },
                                  )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                      Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                style: const TextStyle(fontSize: 13),
                                onTapOutside: (event) {
                                  // Prevent closing dropdown when tapping on search field
                                  _searchFocusNode.requestFocus();
                                },
                              ),
                            ),
                            // const Divider(height: 1),
                          ],
                          if (widget.isMultiSelect) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${widget.selectedValues?.length ?? 0} selected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _closeDropdown(),
                                    child: Text(
                                      'Done',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                          Flexible(
                            child: _filteredItems.isEmpty
                                ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No items found',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                                : Scrollbar(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  final isSelected = _isItemSelected(item);

                                  return InkWell(
                                    onTap: () => _handleItemTap(item),
                                    child: widget.customItemBuilder != null
                                        ? widget.customItemBuilder!(item)
                                        : Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          if (widget.isMultiSelect) ...[
                                            Icon(
                                              isSelected
                                                  ? Icons.check_box
                                                  : Icons
                                                  .check_box_outline_blank,
                                              size: 20,
                                              color: isSelected
                                                  ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  : Colors.grey[400],
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          Expanded(
                                            child:
                                            _buildHighlightedText(
                                                item),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Add padding to account for safe area at the bottom
                          if (!shouldOpenUpwards)
                            SizedBox(height: safeAreaBottom),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalLabelStyle = widget.labelStyle ??
        TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        );

    final finalSelectedStyle = widget.selectedItemStyle ??
        const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black,
        );

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.isReadOnly ? null : _toggleDropdown,
        child: Container(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.borderColor ?? Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.iconPath != null && widget.iconPath!.isNotEmpty) ...[
                SvgPicture.asset(
                  widget.iconPath!,
                  width: widget.iconSize,
                  height: widget.iconSize,
                  color: widget.iconColor ?? Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          text: widget.label,
                          style: finalLabelStyle,
                          children: widget.isRequired
                              ? [
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            )
                          ]
                              : [],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    /*
                    // multiselect
                    Text(
                      _getDisplayText(),
                      style: finalSelectedStyle,
                      overflow: TextOverflow.ellipsis,
                    ),*/

                    Text(
                      (widget.value == null || widget.value!.isEmpty)
                          ? (widget.placeholder ?? '')   // ✅ placeholder support
                          : widget.value!,
                      style: finalSelectedStyle.copyWith(
                        color: (widget.value == null || widget.value!.isEmpty)
                            ? Colors.grey  // placeholder styling
                            : finalSelectedStyle.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                  ],
                ),
              ),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: widget.iconColor ?? Theme.of(context).primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}




