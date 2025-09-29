import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppTheme.textColor.withValues(alpha: 0.4),
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
    );
  }
}