import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import 'screen_helpers.dart';

/// 23 — Sign in with email, Apple, or Google.
///
/// v0.1: email sign-in works against the local account store. Apple and
/// Google are not connected yet — tapping them says so honestly instead
/// of pretending.
class SignInScreen extends StatefulWidget {
  /// Creates a [SignInScreen].
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _signingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AdaptiveScaffold(
      title: 'Sign in',
      showNav: false,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Welcome back'),
            const SizedBox(height: 6),
            const Text(
              'Sign in to PARALLEL',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your branches, snapshots and merges live on your account, '
              'on every device.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Email'),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'you@studio.example',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Password'),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signIn(controller),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _signingIn ? null : () => _signIn(controller),
                child: Text(_signingIn ? 'Signing in…' : 'Sign in'),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      fontSize: 12,
                      color: ParallelPalette.muted,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    letter: 'A',
                    label: 'Apple',
                    onTap: () => _socialNotReady(context, 'Apple'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    letter: 'G',
                    label: 'Google',
                    onTap: () => _socialNotReady(context, 'Google'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.createAccount);
                },
                child: const Text('No account yet? Create one ›'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () async {
                  await controller.continueAsGuest();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      Routes.projects,
                    );
                  }
                },
                child: const Text('Prefer to look first? Continue as guest'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn(AppController controller) async {
    setState(() => _signingIn = true);
    try {
      await controller.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.projects,
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        // Unverified accounts resume at the verify screen.
        if (controller.auth.pendingEmail != null &&
            e.message.contains('not verified')) {
          Navigator.pushNamed(context, Routes.verify);
        } else {
          showError(context, e);
        }
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  void _socialNotReady(BuildContext context, String provider) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$provider sign-in is not connected yet'),
        content: Text(
          'This v0.1 build signs in with email only — $provider sign-in '
          'arrives with the real backend. Use email for now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: ParallelPalette.muted,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.letter,
    required this.label,
    required this.onTap,
  });

  final String letter;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ParallelPalette.glassStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: const BorderSide(color: ParallelPalette.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                letter,
                style: AppTheme.mono(
                  size: 15,
                  color: ParallelPalette.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
