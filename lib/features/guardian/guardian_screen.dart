import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/validators.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/models/remote_config.dart';
import 'package:homeschooling/state/config_providers.dart';
import 'package:homeschooling/state/guardian_providers.dart';
import 'package:homeschooling/strings.dart';

/// Phone -> OTP -> declaration, required once per family before the first child profile can be created
/// (docs/client-guide.md "Guardian verification and consent"). NOTE: the declaration text itself
/// ([Str.guardianDeclarationDraft]) is a DRAFT pending legal review.
class GuardianScreen extends ConsumerStatefulWidget {
  const GuardianScreen({super.key});

  @override
  ConsumerState<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends ConsumerState<GuardianScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();
  bool _agreed = false;
  String? _phoneError;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final String? normalized = Validators.normalizePhone(_phone.text);
    setState(() => _phoneError = normalized == null ? Str.guardianInvalidPhone : null);
    if (normalized == null) return;
    await ref.read(guardianProvider.notifier).sendCode(normalized);
  }

  Future<void> _sendEmailCode() async {
    setState(() => _phoneError = null);
    await ref.read(guardianProvider.notifier).sendEmailCode();
  }

  Future<void> _confirm(String noticeVersion) async {
    if (!Validators.isOtp(_code.text) || !_agreed) return;
    final bool ok = await ref.read(guardianProvider.notifier).confirm(code: _code.text, noticeVersion: noticeVersion);
    if (!mounted || !ok) return;
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final GuardianState guardian = ref.watch(guardianProvider);
    final AsyncValue<RemoteConfig> config = ref.watch(remoteConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(Str.guardianTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(Str.guardianIntro),
              const SizedBox(height: 20),
              if (guardian.step == GuardianStep.enterPhone) ..._phoneStep(guardian),
              if (guardian.step == GuardianStep.enterCode) ..._codeStep(guardian, config),
              if (guardian.error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(errorText(guardian.error!), style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _phoneStep(GuardianState guardian) {
    return <Widget>[
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(labelText: Str.guardianPhoneLabel, helperText: Str.guardianPhoneHint, errorText: _phoneError),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: guardian.busy ? null : _sendCode,
        child: guardian.busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text(Str.guardianSendCode),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: guardian.busy ? null : _sendEmailCode,
        child: const Text(Str.guardianEmailCta),
      ),
      const SizedBox(height: 4),
      Text(Str.guardianEmailHint, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
    ];
  }

  List<Widget> _codeStep(GuardianState guardian, AsyncValue<RemoteConfig> config) {
    final String? noticeVersion = config.value?.declarationNoticeVersion;
    return <Widget>[
      Text('${Str.guardianCodeSentTo} ${guardian.destination ?? guardian.phone ?? ''}'),
      const SizedBox(height: 12),
      TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: const InputDecoration(labelText: Str.guardianCodeLabel),
      ),
      if (guardian.devCode != null) ...<Widget>[
        const SizedBox(height: 4),
        Text('${Str.guardianDevCodeNotice} ${guardian.devCode}', style: Theme.of(context).textTheme.bodySmall),
      ],
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(Str.guardianDeclarationDraft, style: TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(Str.guardianDeclarationLegalNotice, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _agreed,
        onChanged: (bool? v) => setState(() => _agreed = v ?? false),
        title: const Text(Str.guardianDeclarationCheckbox),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: (guardian.busy || noticeVersion == null) ? null : () => _confirm(noticeVersion),
        child: guardian.busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text(Str.guardianConfirmCta),
      ),
      TextButton(
        onPressed: guardian.busy ? null : () => ref.read(guardianProvider.notifier).reset(),
        child: const Text(Str.guardianResend),
      ),
    ];
  }
}
