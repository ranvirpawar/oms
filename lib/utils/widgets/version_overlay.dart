import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionOverlay extends StatefulWidget {
  final Widget child;

  const VersionOverlay({
    super.key,
    required this.child,
  });

  @override
  State<VersionOverlay> createState() => _VersionOverlayState();
}

class _VersionOverlayState extends State<VersionOverlay> {
  String version = '';

  @override
  void initState() {
    super.initState();
    _getVersion();
  }

  Future<void> _getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = 'v${packageInfo.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Version text in bottom right corner
        Positioned(
          bottom: 8,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              version,
              style: const TextStyle(
                fontSize: 8,
                color: Colors.black,
                fontWeight: FontWeight.w300,

                decoration:
                TextDecoration.none, // Explicitly remove any decoration
                decorationStyle: TextDecorationStyle.solid,
                inherit: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}