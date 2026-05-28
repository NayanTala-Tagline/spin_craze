import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';

/// Shows italic "This section may contain ads" text only when [show] is true.
/// Drop this above any Claim Reward button that may show a rewarded ad.
class AdDisclaimerText extends StatelessWidget {
  final bool show;

  const AdDisclaimerText({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.h8),
      child: Text(
        context.l10n.adDisclaimer,
        textAlign: TextAlign.center,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.themeTextColors.muted,
          fontSize: AppSize.sp12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
