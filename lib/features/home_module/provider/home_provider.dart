import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/features/home_module/widgets/daily_checkin_dialog.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeProvider extends ChangeNotifier {
  final _db = Injector.instance<AppDB>();
  final _fireStore = FirebaseFirestore.instance;

  HomeProvider() {
    _showCheckinDialogIfNeeded();
  }

  void _showCheckinDialogIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavKey.currentContext;
      if (ctx == null) return;
      if (isRewardClaimed) return;

      showDialog(
        context: ctx,
        builder: (_) => DailyCheckinDialog(
          currentDay: currentCheckInDay,
          rewardCoins: dailyRewardCoins,
          onClaim: () {
            ctx.pop();
            claimReward(ctx);
          },
        ),
      );
    });
  }

  String get userName {
    final user = _db.userModel;
    if (user == null) return 'Welcome Back';
    return user.name;
  }

  double get totalCoins => _db.userModel?.coin ?? 0;
  double get xp => _db.userModel?.xp ?? 0;
  double get level => _db.userModel?.level ?? 1;
  int get streak => _db.userModel?.checkInStreak ?? 0;
  int get totalClaimDays => _db.userModel?.totalClaimDays ?? 0;

  /// The day slot the user is currently on (1-7).
  /// Resets to 1 if they missed a day or completed the full 7-day cycle.
  int get currentCheckInDay {
    final user = _db.userModel;
    if (user == null || user.lastCheckInDate == null) return 1;

    final today = _dateOnly(DateTime.now());
    final last = _dateOnly(user.lastCheckInDate!);
    final diff = today.difference(last).inDays;

    if (diff == 0) return user.checkInStreak; // already claimed today
    if (diff == 1) {
      return user.checkInStreak == 7 ? 1 : user.checkInStreak + 1;
    }
    return 1; // missed >= 1 day -> reset
  }

  bool get isRewardClaimed {
    final lastDate = _db.userModel?.lastCheckInDate;
    if (lastDate == null) return false;
    return _dateOnly(DateTime.now()) == _dateOnly(lastDate);
  }

  int get dailyRewardCoins => currentCheckInDay * 10;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> claimReward(BuildContext context) async {
    if (isRewardClaimed) return;

    final navCtx = rootNavKey.currentContext ?? context;
    final earned = await RewardAdService.showDailyCheckin(
      navCtx,
      defaultCoins: dailyRewardCoins,
    );
    if (earned == null) return;

    await _grantDailyReward(earned);
    notifyListeners();
  }

  Future<void> _grantDailyReward(int coins) async {
    final user = _db.userModel;
    if (user == null) return;

    final day = currentCheckInDay;

    final updated = user.copyWith(
      coin: user.coin + coins,
      checkInStreak: day,
      lastCheckInDate: DateTime.now(),
      totalClaimDays: user.totalClaimDays + 1,
    );

    _db.userModel = updated;

    await _fireStore.collection('users').doc(user.userId).update({
      'coin': updated.coin,
      'check_in_streak': updated.checkInStreak,
      'last_check_in_date': Timestamp.fromDate(updated.lastCheckInDate!),
      'total_claim_days': updated.totalClaimDays,
    });
  }

  void refresh() {
    notifyListeners();
  }
}
