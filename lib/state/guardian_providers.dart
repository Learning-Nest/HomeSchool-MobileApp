import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/state/environment.dart';

enum GuardianStep { enterPhone, enterCode, done }

class GuardianState {
  const GuardianState({
    this.step = GuardianStep.enterPhone,
    this.phone,
    this.destination,
    this.verificationId,
    this.devCode,
    this.busy = false,
    this.error,
  });

  final GuardianStep step;
  final String? phone;

  /// Where the code went, for display: the typed phone number, or the masked account email ("p***@gmail.com").
  final String? destination;
  final String? verificationId;

  /// Only ever set in `dev`/`nonprod`; never shown in a production build (see [Str.guardianDevCodeNotice]).
  final String? devCode;
  final bool busy;
  final ApiException? error;

  GuardianState copyWith({
    GuardianStep? step,
    String? phone,
    String? destination,
    String? verificationId,
    String? devCode,
    bool? busy,
    ApiException? error,
    bool clearError = false,
  }) {
    return GuardianState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      destination: destination ?? this.destination,
      verificationId: verificationId ?? this.verificationId,
      devCode: devCode ?? this.devCode,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Phone (SMS) or account email -> code -> declaration flow (docs/client-guide.md "Guardian verification and consent").
class GuardianNotifier extends Notifier<GuardianState> {
  @override
  GuardianState build() => const GuardianState();

  AppEnvironment get _env => ref.read(environmentProvider);
  String? get _familyId => ref.read(authProvider).family?.familyId;

  Future<bool> sendCode(String normalizedPhone) async {
    final String? familyId = _familyId;
    if (familyId == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final result = await _env.familyRepository.startGuardianVerification(familyId, normalizedPhone);
      state = GuardianState(
        step: GuardianStep.enterCode,
        phone: normalizedPhone,
        destination: normalizedPhone,
        verificationId: result.verificationId,
        devCode: result.devCode,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e);
      return false;
    }
  }

  /// Emails the code to the signed-in account's own address (the server picks the address; the app never sends one).
  Future<bool> sendEmailCode() async {
    final String? familyId = _familyId;
    if (familyId == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final result = await _env.familyRepository.startGuardianVerification(familyId, null, channel: 'email');
      state = GuardianState(
        step: GuardianStep.enterCode,
        destination: result.destinationHint ?? ref.read(authProvider).user?.email,
        verificationId: result.verificationId,
        devCode: result.devCode,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e);
      return false;
    }
  }

  /// [noticeVersion] must be `RemoteConfig.declarationNoticeVersion` from `/v1/config`.
  Future<bool> confirm({required String code, required String noticeVersion}) async {
    final String? familyId = _familyId;
    final String? verificationId = state.verificationId;
    if (familyId == null || verificationId == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _env.familyRepository.confirmGuardianVerification(
        familyId: familyId,
        verificationId: verificationId,
        code: code,
        noticeVersion: noticeVersion,
      );
      state = state.copyWith(step: GuardianStep.done, busy: false);
      await ref.read(authProvider.notifier).refreshMe();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e);
      return false;
    }
  }

  void reset() => state = const GuardianState();

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }
}

final NotifierProvider<GuardianNotifier, GuardianState> guardianProvider =
    NotifierProvider<GuardianNotifier, GuardianState>(GuardianNotifier.new);
