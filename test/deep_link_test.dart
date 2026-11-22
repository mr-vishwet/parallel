import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:parallel/app.dart';
import 'package:parallel/core/routes.dart';
import 'package:parallel/screens/diff_screen.dart';
import 'package:parallel/screens/projects_screen.dart';
import 'package:parallel/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Routes that take arguments: a bare deep link (no arguments) must
  /// fall back to Projects instead of throwing on a null cast.
  const argRoutes = [
    Routes.snapshotDetail,
    Routes.diff,
    Routes.changeDetail,
    Routes.restore,
    Routes.restored,
    Routes.merge,
    Routes.conflict,
    Routes.merged,
  ];

  for (final route in argRoutes) {
    testWidgets('bare deep link $route falls back to Projects',
        (tester) async {
      await tester.pumpWidget(const ParallelApp());
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);

      final context = tester.element(find.byType(WelcomeScreen));
      Navigator.of(context).pushNamed(route);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProjectsScreen), findsOneWidget);
    });
  }

  testWidgets('diff with valid arguments still opens the diff',
      (tester) async {
    await tester.pumpWidget(const ParallelApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(WelcomeScreen));
    Navigator.of(context).pushNamed(
      Routes.diff,
      arguments: const DiffArgs(sourceId: 'cinematic', targetId: 'main'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DiffScreen), findsOneWidget);
  });
}
