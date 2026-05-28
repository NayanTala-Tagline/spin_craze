import 'package:flutter/material.dart';

typedef RewardedConsentBuilder = Future<bool> Function(BuildContext context);

/// Controls the consent dialog shown before a rewarded ad is displayed.
///
/// Call [setConsentDialogBuilder] once at app startup (e.g. in `main.dart`)
/// to supply your own dialog. The builder must return `true` when the user
/// opts in and `false` when they decline. If no builder is set a built-in
/// dialog is used as fallback.
class RewardedConsent {
  RewardedConsent._();

  static RewardedConsentBuilder? _builder;

  /// Register a custom consent dialog builder.
  ///
  /// Example:
  /// ```dart
  /// RewardedConsent.setConsentDialogBuilder((context) async {
  ///   return await showDialog<bool>(
  ///     context: context,
  ///     builder: (_) => MyConsentDialog(),
  ///   ) ?? false;
  /// });
  /// ```
  static void setConsentDialogBuilder(RewardedConsentBuilder builder) {
    _builder = builder;
  }

  /// Shows the consent dialog and returns `true` if the user opted in.
  /// Called automatically by [RewardedAdManager.show].
  static Future<bool> requestConsent(BuildContext context) {
    if (_builder != null) return _builder!(context);
    return _showDefaultDialog(context);
  }

  static Future<bool> _showDefaultDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _DefaultConsentDialog(),
        ) ??
        false;
  }
}

class _DefaultConsentDialog extends StatelessWidget {
  const _DefaultConsentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.play_circle_outline, size: 40),
      title: const Text('Watch a Rewarded Ad?'),
      content: const Text(
        'Watch a short ad to earn your reward. '
        'This helps keep the app free for everyone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No Thanks'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Opt In'),
        ),
      ],
    );
  }
}
