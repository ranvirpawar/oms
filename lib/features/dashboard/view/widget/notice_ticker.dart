import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../dashboard_controller/dashboard_controller.dart';

class _NoticeTicker extends StatefulWidget {
  final DashboardController controller;

  const _NoticeTicker({required this.controller});

  @override
  State<_NoticeTicker> createState() => _NoticeTickerState();
}

class _NoticeTickerState extends State<_NoticeTicker> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final notices = widget.controller.notices;
      if (notices.isEmpty) return;
      setState(() => _index = (_index + 1) % notices.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final notices = widget.controller.notices;
      if (notices.isEmpty) return const SizedBox.shrink();
      final safeIndex = _index % notices.length;
      final notice = notices[safeIndex];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: notice.color.withOpacity(isDark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: notice.color, width: 3)),
        ),
        child: Row(
          children: [
            Icon(notice.icon, color: notice.color, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: anim.drive(
                      Tween(begin: const Offset(0, 0.4), end: Offset.zero),
                    ),
                    child: child,
                  ),
                ),
                child: Text(
                  notice.message,
                  key: ValueKey('${notice.message}-$safeIndex'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF1D2333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}