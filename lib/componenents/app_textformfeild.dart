import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
// login_controller.dart

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String svgAssetPath;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;
  final List<TextInputFormatter>? inputFormatters;
  final Color? cursorColor;

  const CustomTextFormField({
    super.key,
    this.controller,
    required this.hintText,
    required this.svgAssetPath,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.inputFormatters,
    this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       /* Text(
          hintText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),*/
        TextFormField(
          controller: controller,
          validator: validator,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          textAlign: TextAlign.start,
          obscureText: isPassword && !isPasswordVisible,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: cursorColor,
          cursorWidth: 2,
          cursorRadius: const Radius.circular(4),
          decoration: InputDecoration(

            hintText: hintText,
            hintStyle: TextStyle(

              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset(
                svgAssetPath,
                width: 24,
                height: 24,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.8),
              ),
            )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.white,
                width: 1,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }
}

/*// Updated CustomTextFormField to support modern design
class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String svgAssetPath;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextFormField({
    super.key,
    this.controller,
    required this.hintText,
    required this.svgAssetPath,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.inputFormatters
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hintText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          textAlign: TextAlign.start,
          obscureText: isPassword && !isPasswordVisible,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset(
                svgAssetPath,
                width: 24,
                height: 24,
                color: AppColors.primary,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.primary,
              ),
            )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}*/

