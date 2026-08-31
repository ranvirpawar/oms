import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AnimatedSearchBar extends StatefulWidget {
  final List<String> hintValues;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const AnimatedSearchBar({
    super.key,
    required this.hintValues,
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  int currentIndex = 0;
  late TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;

      if (_controller.text.isEmpty) {
        setState(() {
          currentIndex =
              (currentIndex + 1) % widget.hintValues.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ VERY IMPORTANT
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_controller.text.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                children: [
                  Text(
                    'Search by ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.hintValues[currentIndex],
                      key: ValueKey(currentIndex),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          TextField(
            controller: _controller,
            onChanged: (val) {
              setState(() {});
              widget.onChanged(val);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent, // ✅ THIS FIXES IT
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.primary,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onClear?.call();
                },
              )
                  : const SizedBox(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}