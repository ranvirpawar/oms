import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ScaffoldTopContainer extends StatelessWidget {
  const ScaffoldTopContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: double.infinity,
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          const Spacer(),
          Container(
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(40),
                topLeft: Radius.circular(40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
