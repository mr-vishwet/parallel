import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import 'screen_helpers.dart';

/// 24 — Create an account: name, email, password. Then verify.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AdaptiveScaffold(
      title: 'Create account',
      showNav: false,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Join PARALLEL'),
            const SizedBox(height: 6),
            const Text(
              'One account holds\nyour projects',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The demo stays available either way.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Mara'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 16),
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
                hintText: '8 characters or more',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(controller),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _creating ? null : () => _create(controller),
                child: Text(_creating ? 'Creating…' : 'Create account'),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'By creating an account you agree to the terms · read them first',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: ParallelPalette.secondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: ParallelPalette.paper2,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: ParallelPalette.green,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Guests create nothing, so there is nothing to '
                        'move — your account starts empty and the demo '
                        'stays where it was.',
                        style: TextStyle(
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
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.signIn);
                },
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(AppController controller) async {
    setState(() => _creating = true);
    try {
      await controller.createAccount(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushNamed(context, Routes.verify);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
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
