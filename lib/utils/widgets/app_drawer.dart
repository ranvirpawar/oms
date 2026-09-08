import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/view/change_password_view.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../constants/app_assets.dart';
import '../../features/dashboard/dashboard_controller/dashboard_controller.dart';
import '../../routes/route_manager.dart';
import '../../services/snackbar_service.dart';

class CustomDrawer extends StatelessWidget {
  final DashboardController controller;

  const CustomDrawer({super.key, required this.controller});

  // Using function references for navigation
  List<DrawerItem> _getDrawerItems() {
    return [
      // DrawerItem(
      //     icon: Icons.settings_outlined,
      //     titleKey: "Settings",
      //     navigationFunction: _navigateToSettings,
      //     isLogout: false),
      /* DrawerItem(
          icon: Icons.lock_outline,
          titleKey: 'Change Password',
          navigationFunction: _generatePasscode,
          isLogout: false),*/
      DrawerItem(icon: Icons.home, titleKey: 'Home', navigationFunction: () {}, isLogout: false),
      DrawerItem(icon: Icons.history, titleKey: 'Assigned Tasks', navigationFunction: () {}, isLogout: false),
      DrawerItem(icon: Icons.note_alt, titleKey: 'Tasks History', navigationFunction: () {}, isLogout: false),
      DrawerItem(icon: Icons.punch_clock, titleKey: 'End Shift', navigationFunction: () {}, isLogout: false),
      DrawerItem(icon: Icons.calendar_today, titleKey: 'Daily Reconciliation', navigationFunction: () {}, isLogout: false),

      // DrawerItem(
      //     icon: Icons.help_outline,
      //     titleKey: "Help & Support",
      //     navigationFunction: _openSupport,
      //     isLogout: false),
      DrawerItem(icon: Icons.logout, titleKey: 'Logout', navigationFunction: () => Get.find<AuthManager>().logoutUser(clearCredentials: true), isLogout: true),
    ];
  }

  void _navigateToSettings() {
    SnackBarService.to.showComingSoonNotification();
    // Add navigation logic
  }

  void _generatePasscode() {
    Get.to(() => const ChangePasswordView());
  }

  void _openSupport() {
    SnackBarService.to.showComingSoonNotification();
    // Add support logic
  }

  bool hasValidImage(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawerItems = _getDrawerItems();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Modern Profile Header
          Obx(
            () => Container(
              padding: const EdgeInsets.fromLTRB(20, 45, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)]),
              ),
              child: Column(
                children: [
                  // Profile Avatar
                  GestureDetector(
                    onTap: () {
                      RouteManager.navigateToProfilePage(controller.userProfile.value);
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            gradient: !hasValidImage(controller.userProfile.value?.imagePath)
                                ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)])
                                : null,
                          ),
                          child: ClipOval(
                            child: hasValidImage(controller.userProfile.value?.imagePath)
                                ? Image.network(
                                    controller.userProfile.value!.imagePath,
                                    fit: BoxFit.cover,
                                    width: 70,
                                    height: 70,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
                                        child: const Center(
                                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 70,
                                        height: 70,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
                                        child: const Icon(Icons.person_outline, size: 35, color: Colors.white),
                                      );
                                    },
                                  )
                                : const Icon(Icons.person_outline, size: 35, color: Colors.white),
                          ),
                        ),
                        // Online status indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User Info Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Name
                      Text(
                        _getUserName(),
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Designation
                      Text(
                        controller.userProfile.value?.designation ?? 'Loading...',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 0),

                      // Organization and Facility
                      _buildSmallInfoChip(icon: Icons.info_outline_rounded, label: _getOrgFacilityInfo(), theme: theme),

                      // Text(
                      //   _getOrgFacilityInfo(),
                      //   style: theme.textTheme.bodySmall?.copyWith(
                      //     color: Colors.white.withOpacity(0.8),
                      //     fontWeight: FontWeight.w400,
                      //   ),
                      //   textAlign: TextAlign.center,
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      const SizedBox(height: 6),

                      // Additional Info Row (Blood Group, Mobile, Emp Code)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (controller.userProfile.value?.bloodGroup != null && controller.userProfile.value!.bloodGroup.isNotEmpty && controller.userProfile.value!.bloodGroup != 'NA') ...[
                            _buildSmallInfoChip(icon: Icons.bloodtype_outlined, label: controller.userProfile.value!.bloodGroup, theme: theme),
                            const SizedBox(width: 6),
                          ],
                          if (controller.userProfile.value?.perMobile != null && controller.userProfile.value!.perMobile.isNotEmpty) ...[
                            _buildSmallInfoChip(icon: Icons.phone_outlined, label: _formatMobile(controller.userProfile.value!.perMobile), theme: theme),
                            const SizedBox(width: 6),
                          ],
                          if (controller.userProfile.value?.empCode != null) ...[_buildSmallInfoChip(icon: Icons.badge_outlined, label: 'EMP: ${controller.userProfile.value!.empCode}', theme: theme)],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: drawerItems.length,
              itemBuilder: (context, index) {
                final item = drawerItems[index];

                // Special styling for logout button
                if (item.isLogout) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.error.withOpacity(0.3), width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(item.icon, color: theme.colorScheme.error, size: 24),
                      ),
                      title: Text(
                        item.titleKey,
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                      ),
                      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error.withOpacity(0.6), size: 22),
                      onTap: () {
                        Navigator.of(context).pop();
                        item.navigationFunction();
                      },
                    ),
                  );
                }

                // Regular menu items with modern styling
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(item.icon, color: theme.colorScheme.primary, size: 24),
                    ),
                    title: Text(
                      item.titleKey,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                    ),
                    trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 22),
                    onTap: () {
                      Navigator.of(context).pop();
                      item.navigationFunction();
                    },
                  ),
                );
              },
            ),
          ),

          // App Footer with Logo
          const DrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildSmallInfoChip({required IconData icon, required String label, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _getUserName() {
    final profile = controller.userProfile.value;
    if (profile?.name != null && profile!.name.isNotEmpty) {
      return profile.name;
    } else if (profile?.firstName != null || profile?.lastName != null) {
      final firstName = profile?.firstName ?? '';
      final lastName = profile?.lastName ?? '';
      final fullName = '$firstName $lastName'.trim();
      return fullName.isNotEmpty ? fullName : 'Loading...';
    }
    return 'Loading...';
  }

  String _getOrgFacilityInfo() {
    final profile = controller.userProfile.value;
    final org = profile?.orgName ?? '';
    final facility = profile?.facilityName ?? '';

    if (org.isNotEmpty && facility.isNotEmpty) {
      return '$org \n$facility';
    } else if (org.isNotEmpty) {
      return org;
    } else if (facility.isNotEmpty) {
      return facility;
    }
    return '...';
  }

  String _formatMobile(String? mobile) {
    if (mobile == null || mobile.isEmpty) return 'N/A';
    if (mobile.length >= 4) {
      return '***${mobile.substring(mobile.length - 4)}';
    }
    return mobile;
  }
}

class DrawerFooter extends StatefulWidget {
  const DrawerFooter({super.key});

  @override
  State<DrawerFooter> createState() => DrawerFooterState();
}

class DrawerFooterState extends State<DrawerFooter> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = 'v${info.version}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppAssets.lifenityLogo, width: 120, height: 40),
          if (_version.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _version,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.45), fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.4),
            ),
          ],
        ],
      ),
    );
  }
}

// Updated DrawerItem class to support both IconData and String
class DrawerItem {
  final dynamic icon; // Can be IconData or String (for SvgPicture.asset)
  final String titleKey;
  final Function navigationFunction;
  final bool isLogout;

  DrawerItem({required this.icon, required this.titleKey, required this.navigationFunction, this.isLogout = false});
}
