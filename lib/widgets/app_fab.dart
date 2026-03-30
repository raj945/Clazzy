import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Consistent FAB (Floating Action Button) widget used across all screens
/// This ensures visual consistency throughout the app

class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;

  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.accent,
      foregroundColor: foregroundColor ?? Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      mini: mini,
      tooltip: tooltip,
      child: Icon(icon, size: mini ? 20 : 24),
    );
  }
}

/// Extended FAB with label - for more important actions
class AppExtendedFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppExtendedFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.accent,
      foregroundColor: foregroundColor ?? Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

/// Column of FABs for screens with multiple actions (like Goals screen)
class AppMultiFloatingActionButton extends StatelessWidget {
  final List<FABItem> items;
  final double spacing;

  const AppMultiFloatingActionButton({
    super.key,
    required this.items,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < items.length - 1 ? spacing : 0,
          ),
          child: FloatingActionButton(
            heroTag: 'fab_$index',
            onPressed: item.onPressed,
            backgroundColor: item.backgroundColor ?? AppColors.accent,
            foregroundColor: item.foregroundColor ?? Colors.black,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            mini: item.mini,
            tooltip: item.tooltip,
            child: Icon(item.icon, size: item.mini ? 20 : 24),
          ),
        );
      }).toList(),
    );
  }
}

/// Data class for multi-FAB items
class FABItem {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;

  const FABItem({
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });
}
