import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.gradient,
    this.elevation,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          gradient: gradient,
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: card,
      );
    }

    return card;
  }
}