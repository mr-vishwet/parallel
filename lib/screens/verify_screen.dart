import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import 'screen_helpers.dart';

/// 25 — Verify with the 6-digit code.
///
/// v0.1: no email is sent (there is no backend yet). The demo code is
/// shown on this screen, clearly labelled as a demo code, so the flow is
/// completable. Real email verification arrives with the backend.
class VerifyScreen extends StatefulWidget {
  /// Creates a [VerifyScreen].
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _codeController = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final email = controller.auth.pendingEmail ?? 'your email';
    final demoCode = controller.auth.pendingCode;
    final entered = _codeController.text;

    return AdaptiveScaffold(
      title: 'Verify',
      showNav: false,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Check your email'),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: 'A 6-digit code is on its way to ',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: ParallelPalette.ink,
                ),
                children: [
                  TextSpan(
                    text: email,
                    style: AppTheme.mono(
                      size: 18,
                      color: ParallelPalette.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'It works for 15 minutes.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                for (var i = 0; i < 6; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 5 ? 0 : 8),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: i < entered.length
                                ? ParallelPalette.cutRed
                                    .withValues(alpha: 0.55)
                                : ParallelPalette.hairline,
                          ),
                          color: ParallelPalette.glassStrong,
                        ),
                        child: Text(
                          i < entered.length ? entered[i] : '',
                          style: AppTheme.mono(
                            size: 20,
                            color: ParallelPalette.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${entered.length} of 6 digits',
              style: AppTheme.mono(
                size: 13,
                color: ParallelPalette.muted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '6-digit code',
                hintText: 'Enter the code',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _verify(controller),
              autofocus: true,
            ),
            if (demoCode != null) ...[
              const SizedBox(height: 12),
              Card(
                color: ParallelPalette.paper2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: ParallelPalette.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'v0.1 demo — no email is sent yet. Your code is '
                          '$demoCode.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: ParallelPalette.secondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _verifying || entered.length != 6 ? null : () => _verify(controller),
                child: Text(_verifying ? 'Verifying…' : 'Verify'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () async {
                  await controller.resendCode();
                  if (context.mounted) {
                    showMessage(context, 'A new code was generated.');
                    setState(() {});
                  }
                },
                child: const Text('No code yet · Send it again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify(AppController controller) async {
    setState(() => _verifying = true);
    try {
      await controller.verify(_codeController.text);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.migrate,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }
}
