import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class CustomDropdown extends StatelessWidget {
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
  final Color? borderColor;
  final Color? iconColor;
  final EdgeInsets? padding;
  final double borderRadius;
  final double iconSize;
  final String? placeholder;
  // non mandatory suffix
  final Widget? suffix;
  final bool showSrNo;


  const CustomDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.iconPath,
    this.isRequired = true,
    this.isReadOnly = false,
    this.labelStyle,
    this.itemStyle,
    this.selectedItemStyle,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.padding,
    this.borderRadius = 8.0,
    this.iconSize = 24.0,
    this.placeholder,
    this.suffix,
    this.showSrNo = false,
  });

  @override
  Widget build(BuildContext context) {
    final finalLabelStyle = labelStyle ??
        TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        );
    final finalSelectedStyle = selectedItemStyle ??
        const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black,
        );

    // Validate value: set to null if not in items
    final validValue = value != null && items.contains(value) ? value : null;

    final displayText = validValue ?? (placeholder ?? 'Select an option');
    final displayStyle = validValue != null
        ? finalSelectedStyle
        : finalSelectedStyle.copyWith(color: Colors.grey[600]);

    return InkWell(
      onTap: isReadOnly || items.isEmpty
          ? null
          : () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (BuildContext bc) {
            String searchText = '';
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                final filteredItems = items
                    .where((item) => item.toLowerCase().contains(searchText.toLowerCase()))
                    .toList();
                return SafeArea(
                  child: Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(


                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),

                              labelText: 'Search',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),

                            ),
                            onChanged: (value) {
                              setState(() => searchText = value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.5,
                              ),
                              child: filteredItems.isEmpty
                                  ? const Center(child: Text('No items found'))
                                  : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final isSelected = validValue == item;
                                  final srNo = showSrNo ? '${index + 1}. ' : '';
                                  return ListTile(
                                    title: Text(
                                      '$srNo$item',
                                      style: itemStyle ??
                                          TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.black87,
                                          ),
                                    ),
                                    selected: isSelected,
                                    onTap: () {
                                      onChanged?.call(item);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? Colors.grey[300]!,
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (iconPath != null && iconPath!.isNotEmpty) ...[
              SvgPicture.asset(
                iconPath!,
                width: iconSize,
                height: iconSize,
                color: iconColor ?? Theme.of(context).primaryColor,
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
                        text: label,
                        style: finalLabelStyle,
                        children: isRequired
                            ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                            : [],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayText,
                          style: displayStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: iconColor ?? Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (suffix != null) ...[
              suffix!,
            ],
          ],
        ),
      ),
    );
  }
}
/*
class CustomDropdown extends StatelessWidget {
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
  final Color? borderColor;
  final Color? iconColor;
  final EdgeInsets? padding;
  final double borderRadius;
  final double iconSize;
  final String? placeholder;

  const CustomDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.iconPath,
    this.isRequired = true,
    this.isReadOnly = false,
    this.labelStyle,
    this.itemStyle,
    this.selectedItemStyle,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.padding,
    this.borderRadius = 8.0,
    this.iconSize = 24.0,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final finalLabelStyle = labelStyle ??
        TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        );
    final finalSelectedStyle = selectedItemStyle ??
        const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black,
        );

    // Validate value: set to null if not in items
    final validValue = value != null && items.contains(value) ? value : null;


    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (iconPath != null && iconPath!.isNotEmpty) ...[
            SvgPicture.asset(
              iconPath!,
              width: iconSize,
              height: iconSize,
              color: iconColor ?? Theme.of(context).primaryColor,
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
                      text: label,
                      style: finalLabelStyle,
                      children: isRequired
                          ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                          : [],
                    ),
                  ),
                ),
                
                DropdownButton<String>(
                  isDense: true,

                  value: validValue,
                  hint: Text(
                    placeholder ?? 'Select an option',
                    style: finalSelectedStyle.copyWith(color: Colors.grey[600]),
                  ),
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: iconColor ?? Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  items: items.isEmpty
                      ? null
                      : items.map((String item) {

                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: itemStyle ??
                            TextStyle(
                              fontSize: 12,
                              fontWeight: validValue == item ? FontWeight.bold : FontWeight.normal,
                              color: validValue == item
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black87,
                            ),
                      ),
                    );
                  }).toList(),
                  onChanged: isReadOnly || items.isEmpty ? null : onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/
