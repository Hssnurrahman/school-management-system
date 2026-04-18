import 'package:flutter/material.dart';

void showSuccessSnackBar(BuildContext context, String message) {
  _show(context, message, const Color(0xFF10B981), Icons.check_circle_rounded);
}

void showErrorSnackBar(BuildContext context, String message) {
  _show(context, message, const Color(0xFFEF4444), Icons.error_outline_rounded);
}

void showInfoSnackBar(BuildContext context, String message) {
  _show(context, message, const Color(0xFFF59E0B), Icons.info_outline_rounded);
}

void _show(BuildContext context, String message, Color color, IconData icon) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
