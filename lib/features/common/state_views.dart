import 'package:flutter/material.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/strings.dart';

/// Maps an [ApiException] to short, friendly display text. Kept separate from [ApiException.message]
/// (which is for logs only, per core/api_exception.dart).
String errorText(ApiException e) {
  switch (e.code) {
    case 'network':
      return Str.errorNetwork;
    case 'bad_response':
      return Str.errorBadResponse;
    case 'unauthenticated':
      return Str.errorSessionExpired;
    case 'conflict':
      return Str.errorConflict;
    case 'email_taken':
      return Str.errorEmailTaken;
    case 'validation_error':
      return Str.errorValidation;
    case 'otp_invalid':
      return Str.errorOtpInvalid;
    case 'invalid_credentials':
      return Str.errorInvalidCredentials;
    case 'rate_limited':
      return Str.errorRateLimited;
    case 'delivery_failed':
      return Str.errorDeliveryFailed;
    default:
      return Str.errorGeneric;
  }
}

/// Same as [errorText] but accepts whatever an `AsyncValue.error` handed back (only ever an [ApiException]
/// in this app, but [FutureProvider]'s type is `Object`).
String errorTextFromAny(Object error) => error is ApiException ? errorText(error) : Str.errorGeneric;

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          if (label != null) ...<Widget>[const SizedBox(height: 12), Text(label!)],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  factory ErrorView.fromException(ApiException e, {VoidCallback? onRetry}) {
    return ErrorView(message: errorText(e), onRetry: onRetry);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text(Str.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined, this.action});

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
