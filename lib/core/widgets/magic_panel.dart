import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Standard panel for grouping content: dark purple fill and gold border.
/// Use it for lists, forms and status cards on the next screens.
class MagicPanel extends StatelessWidget {
  const MagicPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: MagicColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MagicColors.goldSoft),
      ),
      child: child,
    );
  }
}
