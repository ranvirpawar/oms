// update_bottom_sheet.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_assets.dart';
import '../../../theme/app_colors.dart';
// update_bottom_sheet.dart

class UpdateBottomSheet extends StatelessWidget {
  final String currentVersion;

  const UpdateBottomSheet({
    super.key,
    required this.currentVersion,
  });

  static void show({required String currentVersion}) {
    Get.bottomSheet(
      UpdateBottomSheet(currentVersion: currentVersion),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 32,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              // Logo
              Center(
                child: Image.asset(
                  AppAssets.lifenityLogo,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width * 0.55,
                ),
              ),
              const SizedBox(height: 18),
              // Banner
              const _Banner(),
              const SizedBox(height: 12),
              // Feature rows
              const _FeatureRow(
                icon: '⚡',
                title: '2× faster load times',
                subtitle: 'Optimised data sync for smoother flows',
              ),
              const _FeatureRow(
                icon: '✨',
                title: 'Refined UI experience',
                subtitle: 'Cleaner screens, fewer taps to get things done',
              ),
              const SizedBox(height: 20),
              // CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _UpdateButton(),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Banner ────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "New version available" pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BlinkDot(),
                const SizedBox(width: 6),
                const Text(
                  'NEW VERSION AVAILABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Lifenity Connect',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "We've fine-tuned every corner to boost\nyour performance & experience.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              height: 1.55,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Blinking dot ──────────────────────────────────────────────────────────

class _BlinkDot extends StatefulWidget {
  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final Animation<double> _anim =
  Tween(begin: 0.3, end: 1.0).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Feature row ───────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 17)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary.withOpacity(0.9),
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ─── Update button with shimmer ────────────────────────────────────────────

class _UpdateButton extends StatefulWidget {
  @override
  State<_UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<_UpdateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _openStore() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      String packageId = packageInfo.packageName;
      if (packageId == 'com.example.lifenity_connect.beta') {
        packageId = 'com.lifenityhealth.connect';
      }
      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageId',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (Platform.isIOS) {

      const uri = 'https://apps.apple.com/in/app/lifenity-connect/id6749895597';
      final appStoreUri = Uri.parse(uri);
      if (await canLaunchUrl(appStoreUri)) {
        await launchUrl(appStoreUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openStore,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, child) {
          return Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  child!,
                  // Shimmer sweep
                  Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(
                        (_shimmer.value * 3) - 1.5,
                        0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update now  •  it only takes a sec',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}
// class UpdateBottomSheet extends StatelessWidget {
//
//   final String currentVersion;
//
//   const UpdateBottomSheet({
//     super.key,
//
//     required this.currentVersion,
//   });
//
//   static void show({
//
//     required String currentVersion,
//   }) {
//     Get.bottomSheet(
//       UpdateBottomSheet( currentVersion: currentVersion),
//       isScrollControlled: true,
//       isDismissible: false,
//       enableDrag: false,
//       backgroundColor: Colors.transparent,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false, // block back button
//       child: Container(
//         decoration: const BoxDecoration(
//           color: Color(0xFF15181F),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//           border: Border(
//             top: BorderSide(color: Color(0x12FFFFFF)),
//             left: BorderSide(color: Color(0x12FFFFFF)),
//             right: BorderSide(color: Color(0x12FFFFFF)),
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Drag handle
//               const SizedBox(height: 14),
//               Container(
//                 width: 36, height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//
//               const SizedBox(height: 14),
//               Center(
//                 child: Image.asset(
//                   AppAssets.lifenityLogo,
//                   fit: BoxFit.contain,
//                   width: MediaQuery.of(context).size.width * 0.6,
//                 ),
//               ),
//               const SizedBox(height: 14),
//               // Banner card
//               _Banner(),
//
//               const SizedBox(height: 14),
//               // What's new list
//               _FeatureRow(
//                 icon: '⚡',
//                 iconColor: const Color(0xFF4F8EF7),
//                 title: '2× faster load times',
//                 subtitle: 'Optimised data sync for smoother flows',
//               ),
//             /*  _FeatureRow(
//                 icon: '🛡️',
//                 iconColor: const Color(0xFF7B5FE8),
//                 title: 'Security enhancements',
//                 subtitle: 'Stronger protection for your health data',
//               ),*/
//               _FeatureRow(
//                 icon: '✨',
//                 iconColor: const Color(0xFF22C55E),
//                 title: 'Refined UI experience',
//                 subtitle: 'Cleaner screens, fewer taps to get things done',
//               ),
//
//               const SizedBox(height: 20),
//
//               // CTA
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: _UpdateButton(),
//               ),
//               const SizedBox(height: 8),
//
//               const SizedBox(height: 28),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ─── Banner ────────────────────────────────────────────────────────────────
//
// class _Banner extends StatelessWidget {
//
//   const _Banner();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20),
//       padding: const EdgeInsets.all(20),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFF1A2240), Color(0xFF1A1A30), Color(0xFF1E2030)],
//         ),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: const Color(0xFF4F8EF7).withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // "New version available" pill
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: const Color(0xFF4F8EF7).withOpacity(0.18),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: const Color(0xFF4F8EF7).withOpacity(0.35),
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _BlinkDot(),
//                 const SizedBox(width: 5),
//                 const Text(
//                   'NEW VERSION AVAILABLE',
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF7EB8FF),
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 14),
//
//           const Text(
//             'Lifenity Connect',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 19,
//               fontWeight: FontWeight.w700,
//               color: Color(0xFFF0F2F8),
//               height: 1.25,
//               letterSpacing: -0.4,
//
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             "We've fine-tuned every corner to boost\nyour performance & experience.",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 12.5,
//               color: const Color(0xFF8899BB),
//               height: 1.5,
//               fontFamily: 'DMSans',
//             ),
//           ),
//           const SizedBox(height: 14),
//
//           /*// Version badge
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             decoration: BoxDecoration(
//               color: const Color(0xFF22C55E).withOpacity(0.12),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: const Color(0xFF22C55E).withOpacity(0.25),
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 6, height: 6,
//                   decoration: const BoxDecoration(
//                     color: Color(0xFF22C55E),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   'v$newVersion is ready to install',
//                   style: const TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF4ADE80),
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//               ],
//             ),
//           ),*/
//         ],
//       ),
//     );
//   }
// }
//
// // ─── Blinking dot ──────────────────────────────────────────────────────────
//
// class _BlinkDot extends StatefulWidget {
//   @override
//   State<_BlinkDot> createState() => _BlinkDotState();
// }
//
// class _BlinkDotState extends State<_BlinkDot>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 1500),
//   )..repeat(reverse: true);
//
//   late final Animation<double> _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
//
//   @override
//   void dispose() { _ctrl.dispose(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _anim,
//       child: Container(
//         width: 5, height: 5,
//         decoration: const BoxDecoration(
//           color: Color(0xFF4F8EF7),
//           shape: BoxShape.circle,
//         ),
//       ),
//     );
//   }
// }
//
// // ─── Feature row ───────────────────────────────────────────────────────────
//
// class _FeatureRow extends StatelessWidget {
//   final String icon;
//   final Color iconColor;
//   final String title;
//   final String subtitle;
//
//   const _FeatureRow({
//     required this.icon,
//     required this.iconColor,
//     required this.title,
//     required this.subtitle,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1C2030),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white.withOpacity(0.07)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 36, height: 36,
//             decoration: BoxDecoration(
//               color: iconColor.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 12.5,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFFF0F2F8),
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors.white.withOpacity(0.45),
//                     fontFamily: 'DMSans',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─── Update button with shimmer ────────────────────────────────────────────
//
// class _UpdateButton extends StatefulWidget {
//   @override
//   State<_UpdateButton> createState() => _UpdateButtonState();
// }
//
// class _UpdateButtonState extends State<_UpdateButton>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _shimmer = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 2500),
//   )..repeat();
//
//   @override
//   void dispose() { _shimmer.dispose(); super.dispose(); }
//
//   Future<void> _openPlayStore() async {
//     final packageInfo = await PackageInfo.fromPlatform();
//     String  packageId = packageInfo.packageName;
//     if (packageId == 'com.example.lifenity_connect.beta') {
//       packageId = 'com.lifenityhealth.connect';
//     }
//     final uri = Uri.parse(
//       'https://play.google.com/store/apps/details?id=$packageId',
//     );
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _openPlayStore,
//       child: AnimatedBuilder(
//         animation: _shimmer,
//         builder: (_, child) {
//           return Container(
//             width: double.infinity,
//             height: 52,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF4F8EF7), Color(0xFF7B5FE8)],
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF4F8EF7).withOpacity(0.35),
//                   blurRadius: 20, offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(16),
//               child: Stack(
//                 children: [
//                   child!,
//                   // Shimmer sweep
//                   Positioned.fill(
//                     child: FractionalTranslation(
//                       translation: Offset(
//                         (_shimmer.value * 3) - 1.5, 0,
//                       ),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               Colors.transparent,
//                               Colors.white.withOpacity(0.12),
//                               Colors.transparent,
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//         child: const Center(
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Update now it only takes a sec',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                   letterSpacing: 0.2,
//                 ),
//               ),
//               SizedBox(width: 8),
//               Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }