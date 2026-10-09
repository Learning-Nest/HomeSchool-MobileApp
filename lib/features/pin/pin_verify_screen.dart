import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/validators.dart';
import 'package:homeschooling/features/common/pin_pad.dart';
import 'package:homeschooling/features/pin/pin_set_screen.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/state/pin_providers.dart';
import 'package:homeschooling/strings.dart';

/// Pushed with `context.push<String>(Routes.pinVerify)`. Pops with the elevation token on success, or null
/// if the parent backs out. Also offers "Forgot PIN?" (account password resets it).
class PinVerifyScreen extends ConsumerStatefulWidget {
  const PinVerifyScreen({super.key});

  @override
  ConsumerState<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<PinVerifyScreen> {
  bool _resetMode = false;
  final TextEditingController _password = TextEditingController();
  final TextEditingController _newPin = TextEditingController();
  String? _resetError;

  @override
  void initState() {
    super.initState();
    // A parent can reach this screen (delete child, exit child mode, ...) before ever choosing a PIN.
    // Send them to set one first instead of asking them to verify a PIN that was never created.
    if (!ref.read(authProvider).pinSet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setupThenVerify();
      });
      return;
    }
    final String? cached = ref.read(pinProvider.notifier).cachedElevationToken();
    if (cached != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop(cached);
      });
    }
  }

  Future<void> _setupThenVerify() async {
    final String? pin = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (BuildContext ctx) => const PinSetScreen()),
    );
    if (!mounted) return;
    if (pin == null) {
      if (ref.read(authProvider).pinSet) {
        // The server said a PIN already exists (and the app has refreshed that): stay here and ask for it.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Str.errorPinAlreadySet)));
        return;
      }
      // The parent backed out of setting a PIN: behave like backing out of verification.
      context.pop();
      return;
    }
    final String? token = await ref.read(pinProvider.notifier).verify(pin);
    if (!mounted) return;
    context.pop(token);
  }

  @override
  void dispose() {
    _password.dispose();
    _newPin.dispose();
    super.dispose();
  }

  Future<void> _verify(String pin) async {
    final String? token = await ref.read(pinProvider.notifier).verify(pin);
    if (!mounted) return;
    if (token != null) context.pop(token);
  }

  Future<void> _reset() async {
    if (_password.text.isEmpty || !Validators.isPin(_newPin.text)) {
      setState(() => _resetError = Str.pinInvalid);
      return;
    }
    final bool ok = await ref.read(pinProvider.notifier).resetWithPassword(password: _password.text, newPin: _newPin.text);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _resetMode = false;
        _resetError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Str.pinResetCta)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final PinState pin = ref.watch(pinProvider);
    final DateTime now = DateTime.now();
    final bool locked = pin.isLocked(now);

    return Scaffold(
      appBar: AppBar(
        title: Text(_resetMode ? Str.pinResetTitle : Str.pinVerifyTitle),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _resetMode ? _resetBody() : _verifyBody(pin, locked, now),
          ),
        ),
      ),
    );
  }

  Widget _verifyBody(PinState pin, bool locked, DateTime now) {
    String? error;
    if (locked) {
      error = Str.pinLockedFor(_formatDuration(pin.remainingLockout(now)));
    } else if (pin.error != null) {
      error = pin.attemptsRemaining != null ? Str.pinAttemptsRemaining(pin.attemptsRemaining!) : Str.pinWrong;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PinPad(onSubmit: locked ? (String _) async {} : _verify, errorText: error, busy: pin.busy),
        const SizedBox(height: 12),
        TextButton(onPressed: () => setState(() => _resetMode = true), child: const Text(Str.pinForgot)),
      ],
    );
  }

  Widget _resetBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(Str.pinResetIntro),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: Str.currentPasswordLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newPin,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(labelText: Str.pinLabel, errorText: _resetError),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _reset, child: const Text(Str.pinResetCta)),
        TextButton(onPressed: () => setState(() => _resetMode = false), child: const Text(Str.cancel)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes + 1} min';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}
