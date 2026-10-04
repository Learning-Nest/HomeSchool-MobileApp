import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/core/validators.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/strings.dart';

/// Shown right after signing in with an emailed temporary password, and the only screen the router allows until
/// the password has been changed (the server refuses everything else with 403 password_change_required).
/// On success the router guard moves the user on to their profiles automatically.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Pre-filled when the user just signed in with it; empty after an app restart, so they type it again.
  late final TextEditingController _current =
      TextEditingController(text: ref.read(authProvider.notifier).tempPasswordInUse ?? '');
  final TextEditingController _new = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).changePassword(currentPassword: _current.text, newPassword: _new.text);
    // Nothing to navigate to here: on success AuthState.tempLogin flips to false and the router redirects.
  }

  String _errorMessage(AuthState auth) {
    final ApiException error = auth.error!;
    return error.code == 'invalid_credentials' ? Str.errorTempPasswordWrong : errorText(error);
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Str.changePasswordTitle), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(Str.changePasswordIntro),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _current,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: Str.temporaryPasswordLabel),
                      validator: (String? v) => (v == null || v.isEmpty) ? Str.invalidPassword : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _new,
                      obscureText: true,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      decoration: const InputDecoration(labelText: Str.newPasswordLabel, helperText: Str.passwordHint),
                      validator: (String? v) {
                        final String value = v ?? '';
                        if (!Validators.isPassword(value)) return Str.invalidPassword;
                        if (value == _current.text) return Str.passwordMustDiffer;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: Str.confirmPasswordLabel),
                      validator: (String? v) => v == _new.text ? null : Str.passwordsDoNotMatch,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (auth.error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(_errorMessage(auth), style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                          : const Text(Str.changePasswordCta),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: auth.busy ? null : () => ref.read(authProvider.notifier).logout(),
                      child: const Text(Str.signOut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
