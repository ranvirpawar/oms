
import 'package:flutter/material.dart';

import '../../../../../constants/app_strings.dart';
import '../../../../../theme/app_colors.dart';

class AddDoctorButton extends StatelessWidget {
  final VoidCallback onAddDoctor;
  const  AddDoctorButton({super.key, required this.onAddDoctor});

  @override
  Widget build(BuildContext context) {
    return  buildCompactReferencesRow(onAddDoctor);
  }
  Widget buildCompactReferencesRow(VoidCallback onAddDoctor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: onAddDoctor,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color : AppColors.surface.withOpacity(0.09),
             /* gradient: LinearGradient(
                  colors: [AppColors.primary900, AppColors.primary700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),*/
              borderRadius: BorderRadius.circular(12),
             /* boxShadow: [
                BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],*/
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(AppStrings.addDoctor,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
