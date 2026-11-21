import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import 'screen_helpers.dart';

/// 29 — Connected accounts: GitHub, Frame.io, and a local folder mirror.
/// Connections mirror or export work; nothing posts or publishes without
/// the user.
///
/// v0.1: the toggles are persisted preferences. GitHub mirroring itself
/// needs the sync server (see Settings → Sync); the toggle records the
/// intent and the screen says so.
class ConnectedScreen extends StatelessWidget {
  /// Creates a [ConnectedScreen].
  const ConnectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final settings = controller.settings;

    return AdaptiveScaffold(
      title: 'Connected accounts',
      subtitle: 'Sync & sharing',
      tab: 3,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('What your account talks to'),
            const SizedBox(height: 6),
            const Text(
              'Connected accounts',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connections mirror or export your work. Nothing posts or '
              'publishes without you.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  _ConnectionRow(
                    letters: 'GH',
                    title: 'GitHub',
                    sub: settings.githubConnected
                        ? 'Pushes mirror to a repo'
                        : 'Mirror branches to a repo',
                    connected: settings.githubConnected,
                    onChanged: (value) async {
                      await controller.setConnection(github: value);
                      if (value && context.mounted) {
                        showMessage(
                          context,
                          'GitHub mirroring needs the sync server — set '
                          'its URL in Settings.',
                        );
                      }
                    },
                  ),
                  const Divider(),
                  _ConnectionRow(
                    letters: 'F',
                    title: 'Frame.io',
                    sub: 'Review links and comments',
                    connected: settings.frameioConnected,
                    onChanged: (value) async {
                      await controller.setConnection(frameio: value);
                      if (value && context.mounted) {
                        showMessage(
                          context,
                          'Frame.io is not connected in this v0.1 build — '
                          'the preference is saved for later.',
                        );
                      }
                    },
                  ),
                  const Divider(),
                  _ConnectionRow(
                    letters: 'HD',
                    title: 'Local folder',
                    sub: '~/Films/Harbour Light',
                    connected: settings.localFolderConnected,
                    onChanged: (value) async {
                      await controller.setConnection(localFolder: value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              color: ParallelPalette.paper2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sharing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Review links are read-only. Dev can branch and '
                      'merge because you invited him, not because the link '
                      'allows it.',
                      style: TextStyle(
                        fontSize: 14,
                        color: ParallelPalette.secondary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.settings);
                },
                child: const Text('Sync settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({
    required this.letters,
    required this.title,
    required this.sub,
    required this.connected,
    required this.onChanged,
  });

  final String letters;
  final String title;
  final String sub;
  final bool connected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ParallelPalette.paper2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              letters,
              style: AppTheme.mono(
                size: 13,
                color: ParallelPalette.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ParallelPalette.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            connected ? 'Connected' : 'Not connected',
            style: AppTheme.mono(
              size: 12,
              color: connected
                  ? ParallelPalette.green
                  : ParallelPalette.muted,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: connected,
            onChanged: onChanged,
            activeThumbColor: ParallelPalette.cutRed,
          ),
        ],
      ),
    );
  }
}
