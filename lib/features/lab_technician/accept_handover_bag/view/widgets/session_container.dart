import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../model/bag_model_new.dart';

class SessionBadgeRow extends StatelessWidget {
  final ScanQRBagOutput scan;
  const SessionBadgeRow({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _Chip(
            label: 'Session #${scan.sessionID}',
            icon: Icons.confirmation_number_outlined,
            theme: theme),
        const SizedBox(width: 10),
        _Chip(
            label: 'Bag #${scan.bagid}',
            icon: Icons.inventory_2_outlined,
            theme: theme),
      ],
    );
  }
}
class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeData theme;
  const _Chip(
      {required this.label, required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}

class _SessionBadgeRow extends StatelessWidget {
  final ScanQRBagOutput scan;
  const _SessionBadgeRow({required this.scan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _Chip(
            label: 'Session #${scan.sessionID}',
            icon: Icons.confirmation_number_outlined,
            theme: theme),
        const SizedBox(width: 10),
        _Chip(
            label: 'Bag #${scan.bagid}',
            icon: Icons.inventory_2_outlined,
            theme: theme),
      ],
    );
  }
}
