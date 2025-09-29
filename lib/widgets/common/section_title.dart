import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final EdgeInsets? padding;

  const SectionTitle({
    Key? key,
    required this.title,
    this.icon,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}