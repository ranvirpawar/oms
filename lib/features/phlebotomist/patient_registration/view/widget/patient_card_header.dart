import 'package:flutter/material.dart';

class PatientCardHeader extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? patientId;
  final String? phoneNumber;
  final String? age;
  final String? gender;
  final String? facilityName;
  final int testCount;
  final VoidCallback? onEditPressed;

  const PatientCardHeader({
    super.key,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.patientId,
    this.phoneNumber,
    this.age,
    this.gender,
    this.facilityName,
    required this.testCount,
    this.onEditPressed,
  });

  String get fullName {
    String capitalize(String? name) {
      if (name == null || name.isEmpty) return '';
      return name[0].toUpperCase() + name.substring(1).toLowerCase();
    }

    final first = capitalize(firstName);
    final middle = middleName?.isNotEmpty == true ? ' ${capitalize(middleName)} ' : ' ';
    final last = capitalize(lastName);

    return '$first$middle$last'.trim();
  }


  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                // Patient Avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.color,
                              ),

                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
