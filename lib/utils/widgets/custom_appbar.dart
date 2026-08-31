import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
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
}


