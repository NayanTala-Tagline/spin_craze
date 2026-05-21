import 'dart:async';

import 'package:ad_manager/models/ad_data.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/services/coin_service.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/rewarded_ad_helper.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// In-app webview page with a countdown timer overlay.
///
/// Shows a webview loading [url]. A floating timer at center-bottom counts
/// down from [durationSeconds]. When done the timer is replaced by a
/// "Claim Reward" button. Tapping it shows the reward ad bottom sheet; coins
/// are granted via [onAdCompleted] only if the user watches or the ad is
/// disabled. Cancelling gives nothing.
class InAppWebViewPage extends StatefulWidget {
  const InAppWebViewPage({
    super.key,
    required this.url,
    required this.title,
    required this.durationSeconds,
    required this.coins,
    required this.adData,
    this.onRewardClaimed,
  });

  final String url;
  final String title;
  final int durationSeconds;
  final int coins;
  final AdData adData;

  /// Called when the reward is successfully claimed (ad watched or ad disabled).
  /// Use this to set the lock in the parent provider.
  final VoidCallback? onRewardClaimed;

  @override
  State<InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  late final WebViewController _controller;
  late int _remaining;
  Timer? _timer;
  bool _completed = false;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        if (mounted) {
          setState(() {
            _remaining = 0;
            _completed = true;
          });
        }
      } else {
        if (mounted) setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onClaimReward() async {
    if (_claimed) return;
    setState(() => _claimed = true);

    final navCtx = rootNavKey.currentContext!;
    await RewardAdHelper.showRewardAdWithBottomSheet(
      context: navCtx,
      adData: widget.adData,
      defaultCoins: widget.coins,
      onAdCompleted: (coins) async {
        await CoinService.addCoins(coins);
        widget.onRewardClaimed?.call();
      },
      onAdCancelled: () {},
    );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: CommonAppBar(title: widget.title, showBack: true, radius: 0),
      body: Stack(
        children: [
          // Webview fills entire body
          WebViewWidget(controller: _controller),

          // Timer / Claim button at center-bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSize.h32,
            child: Center(
              child: _completed
                  ? _ClaimButton(
                      onPressed: _claimed ? null : _onClaimReward,
                      claimed: _claimed,
                    )
                  : _TimerBadge(remaining: _remaining),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timer badge ─────────────────────────────────────────────────────────────

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w20,
        vertical: AppSize.h12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r100),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E3E4F), Color(0xFF0E3E4F).withValues(alpha: 0.5)],
        ),
        border: Border.all(color: const Color(0xFF0E3E4F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSize.w6,
            children: [
              Text(
                '?',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.themeTextColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSize.sp20,
                ),
              ),
              Text(
                'Reward in ${remaining}s..',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.themeTextColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(width: AppSize.w10),
          SizedBox(
            height: AppSize.sp20,
            width: AppSize.sp20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Claim button ────────────────────────────────────────────────────────────

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.onPressed, required this.claimed});

  final VoidCallback? onPressed;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r100);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: AppSize.h44,
          margin: EdgeInsets.symmetric(
            horizontal: AppSize.w20,
            vertical: AppSize.h14,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0E3E4F),
                Color(0xFF0E3E4F).withValues(alpha: 0.5),
              ],
            ),
            border: Border.all(color: const Color(0xFF0E3E4F)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E3E4F).withValues(alpha: 0.4),
                blurRadius: AppSize.r20,
                offset: Offset(0, AppSize.h6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            claimed ? context.l10n.claimed2 : context.l10n.claimRewardButton,
            style: context.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: AppSize.sp16,
            ),
          ),
        ),
      ),
    );
  }
}
