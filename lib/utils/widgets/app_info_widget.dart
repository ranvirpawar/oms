import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoCard extends StatefulWidget {
  const AppInfoCard({super.key});

  @override
  State<AppInfoCard> createState() => _AppInfoCardState();
}

class _AppInfoCardState extends State<AppInfoCard> {
  String _appName = '';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appName = info.appName;
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Version- $_version',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
