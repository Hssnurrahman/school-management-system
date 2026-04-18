import 'package:flutter/material.dart';

/// Shows a standard delete confirmation dialog.
/// [title] defaults to 'Delete?'. [message] is the body text.
/// Calls [onConfirm] when the user taps Delete.
Future<void> showConfirmDeleteDialog({
  required BuildContext context,
  required String message,
  String title = 'Delete?',
  Future<void> Function()? onConfirm,
}) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await onConfirm?.call();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
