import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/validators.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/state/router_guard.dart';
import 'package:homeschooling/strings.dart';

/// "Forgot password?": asks the server to email a temporary password. The server answers identically whether or
/// not the address has an account, so this screen always shows the same confirmation.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  /// Whatever the user had already typed on the sign-in screen.
  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail ?? '');
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    // An error left over from the sign-in screen must not show up here.
    Future<void>.microtask(() {
      if (mounted) ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bool ok = await ref.read(authProvider.notifier).forgotPassword(_email.text);
    if (!mounted) return;
    if (ok) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(Str.forgotPasswordTitle),
        leading: BackButton(onPressed: () => context.go(Routes.login)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent ? _confirmation(context) : _form(context, auth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AuthState auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(Str.forgotPasswordIntro),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const <String>[AutofillHints.email],
            decoration: const InputDecoration(labelText: Str.emailLabel),
            validator: (String? v) => Validators.isEmail(v ?? '') ? null : Str.invalidEmail,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (auth.error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(errorText(auth.error!), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: auth.busy ? null : _submit,
            child: auth.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(Str.forgotPasswordSend),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: () => context.go(Routes.login), child: const Text(Str.backToSignIn)),
        ],
      ),
    );
  }

  Widget _confirmation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.mark_email_read_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(Str.forgotPasswordSentTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text(Str.forgotPasswordSentBody, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => context.go(Routes.login), child: const Text(Str.backToSignIn)),
      ],
    );
  }
}
