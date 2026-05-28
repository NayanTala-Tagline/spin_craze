import 'dart:async';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/services/coin_service.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:flutter/material.dart';

class ScGameZoneProvider extends ChangeNotifier {
  static int get lockMinutes => RemoteConfigService.instance.gameVisitAgainLockTimeMinutes;
  static int get coinsPerGame => RemoteConfigService.instance.gameVisitRewardCoins;

  final _db = Injector.instance<AppDB>();
  Timer? _refreshTimer;

  ScGameZoneProvider() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  String _lockKey(int index) {
    final uid = _db.userModel?.userId ?? 'guest';
    return 'gz_lock_${uid}_$index';
  }

  bool isLocked(int index) {
    final expiry = _db.getValue<int?>(_lockKey(index));
    if (expiry == null) return false;
    return DateTime.now().millisecondsSinceEpoch < expiry;
  }

  String lockCountdown(int index) {
    final expiry = _db.getValue<int?>(_lockKey(index));
    if (expiry == null) return '';
    final diff = expiry - DateTime.now().millisecondsSinceEpoch;
    if (diff <= 0) return '';
    final total = (diff / 1000).ceil();
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Shows reward ad, grants coins, and locks the item.
  /// Returns true if reward was granted, false if user cancelled.
  Future<bool> claimReward(int index) async {
    final navCtx = rootNavKey.currentContext;
    if (navCtx == null) return false;

    final earned = await RewardAdService.showPlayGameReward(
      navCtx,
      defaultCoins: coinsPerGame,
    );
    if (earned == null) return false;

    await CoinService.addCoins(earned);

    final expiry = DateTime.now()
        .add(Duration(minutes: lockMinutes))
        .millisecondsSinceEpoch;
    await _db.setValue(_lockKey(index), expiry);
    notifyListeners();
    return true;
  }

  /// Sets the lock only (no ad, no coins). Used by InAppWebViewPage flow.
  Future<void> setLock(int index) async {
    final expiry = DateTime.now()
        .add(Duration(minutes: lockMinutes))
        .millisecondsSinceEpoch;
    await _db.setValue(_lockKey(index), expiry);
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
