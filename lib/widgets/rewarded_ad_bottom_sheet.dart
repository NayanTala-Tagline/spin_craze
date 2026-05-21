import 'dart:async';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../extension/ext_context.dart';
import '../utils/app_size.dart';
import 'app_button.dart';

class RewardAdBottomSheet extends StatefulWidget {
  final VoidCallback onSupportUs;
  final VoidCallback onCancel;
  final int timerSeconds;
  final bool isHomepage;

  const RewardAdBottomSheet({
    super.key,
    required this.onSupportUs,
    required this.onCancel,
    this.timerSeconds = 3,
    this.isHomepage = false,
  });

  @override
  State<RewardAdBottomSheet> createState() => _RewardAdBottomSheetState();
}

class _RewardAdBottomSheetState extends State<RewardAdBottomSheet> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timerSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        context.pop();
        widget.onSupportUs();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    final txt = context.themeTextColors;

    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r20)),
        border: Border(top: BorderSide(color: tc.border, width: 1)),
      ),
      padding: EdgeInsets.all(AppSize.w20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: AppSize.w40,
            height: AppSize.h4,
            decoration: BoxDecoration(
              color: txt.muted,
              borderRadius: BorderRadius.circular(AppSize.r2),
            ),
          ),
          SizedBox(height: AppSize.h20),

          // Title
          Text(
            context.l10n.supportOurApp,
            style: context.textTheme.titleLarge?.copyWith(color: txt.primary),
          ),
          SizedBox(height: AppSize.h12),

          // Description
          Text(
            context.l10n.supportAppMessage,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(color: txt.secondary),
          ),
          SizedBox(height: AppSize.h20),

          // Timer display
          if (_remainingSeconds > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w16,
                vertical: AppSize.h8,
              ),
              decoration: BoxDecoration(
                color: tc.primaryDeep.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppSize.r12),
                border: Border.all(color: tc.border),
              ),
              child: Text(
                context.l10n.autoStartingInSeconds(_remainingSeconds),
                style: context.textTheme.bodySmall?.copyWith(color: txt.muted),
              ),
            ),

          SizedBox(height: AppSize.h24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.l10n.cancel,
                  variant: AppButtonVariant.outline,
                  onPressed: () {
                    _timer?.cancel();
                    context.pop();
                    widget.onCancel();
                  },
                ),
              ),
              SizedBox(width: AppSize.w12),
              Expanded(
                child: AppButton(
                  label: context.l10n.supportUs,
                  variant: AppButtonVariant.gradient,
                  onPressed: () {
                    _timer?.cancel();
                    context.pop();
                    widget.onSupportUs();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isHomepage ? AppSize.h100 : AppSize.h10),
        ],
      ),
    );
  }
}

/// Helper function to show the reward ad bottom sheet
Future<void> showRewardAdBottomSheet({
  required BuildContext context,
  required VoidCallback onSupportUs,
  required VoidCallback onCancel,
  int timerSeconds = 3,
  bool isHomepage = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => RewardAdBottomSheet(
      onSupportUs: onSupportUs,
      onCancel: onCancel,
      timerSeconds: timerSeconds,
      isHomepage: isHomepage,
    ),
  );
}
