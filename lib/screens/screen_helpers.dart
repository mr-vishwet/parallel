import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../state/app_controller.dart';

/// Guards a mutating action: returns true when the user may edit (signed
/// in), otherwise routes the guest to /upgrade and returns false.
bool requireAccount(BuildContext context, String action) {
  final controller = AppScope.of(context);
  if (controller.canEdit) return true;
  Navigator.pushNamed(
    context,
    Routes.upgrade,
    arguments: UpgradeArgs(action: action),
  );
  return false;
}

/// Shows a short message at the bottom of the screen.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Shows an error message at the bottom of the screen.
void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$error')),
  );
}

/// A yes/no confirmation dialog. Returns true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
