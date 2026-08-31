import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';


class CFormDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final String iconPath;
  final bool isRequired;
  final bool isReadOnly;

  const CFormDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.iconPath,
    this.isRequired = true,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isReadOnly,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: GestureDetector(
          onTap: isReadOnly ? null : onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          text: label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          children: isRequired
                              ? [
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            )
                          ]
                              : [],
                        ),
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
