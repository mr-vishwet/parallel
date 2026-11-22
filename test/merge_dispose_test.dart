import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:parallel/engine/models.dart';
import 'package:parallel/screens/merge_screen.dart';
import 'package:parallel/services/auth_service.dart';
import 'package:parallel/services/store.dart';
import 'package:parallel/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store whose saves can be made to fail after a delay, so a screen can
/// be disposed while a save is still in flight.
class _FailingStore extends WorkspaceStore {
  /// When true, saves wait 500ms and then throw.
  bool failSaves = false;

  @override
  Future<void> saveWorkspace(Workspace workspace) async {
    if (!failSaves) return super.saveWorkspace(workspace);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    throw StateError('simulated save failure');
  }
}

void main() {
  testWidgets(
      'merge screen disposed mid-save does not throw setState after dispose',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Sign in (merging needs an account).
    final auth = AuthService();
    await auth.createAccount(
      name: 'Mara',
      email: 'mara@studio.example',
      password: 'password123',
    );
    await auth.verify(auth.pendingCode!);

    final store = _FailingStore();
    final controller = AppController(store: store, auth: auth);
    await controller.init();

    // Open the cinematic -> main review and resolve every selected
    // conflict, so the merge button is enabled.
    controller.startReview(sourceId: 'cinematic', targetId: 'main');
    final review = controller.review!;
    for (final conflict in review.diff.conflicts) {
      if (review.selectedIds.contains(conflict.id)) {
        controller.resolveConflict(conflict.id, 'source');
      }
    }
    expect(review.plan.canLand, isTrue);

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: const MaterialApp(
          home: MergeScreen(sourceId: 'cinematic', targetId: 'main'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    store.failSaves = true;
    await tester.tap(find.text('Merge into main'));
    await tester.pump();

    // Leave the screen while the failing save is still in flight.
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
