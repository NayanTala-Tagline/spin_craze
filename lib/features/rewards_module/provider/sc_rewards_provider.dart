import 'dart:async';

import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/shared/models/user_model.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScRewardsProvider extends ChangeNotifier {
  ScRewardsProvider() {
    _fetchReferralStats();
  }

  final AppDB _db = Injector.instance<AppDB>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int referralReward = RemoteConfigService.instance.referralRewardAmount;

  final TextEditingController referralController = TextEditingController();

  bool _isApplyingReferral = false;
  bool get isApplyingReferral => _isApplyingReferral;

  String? _errorText;
  String? get errorText => _errorText;

  int _friendsInvited = 0;
  int get friendsInvited => _friendsInvited;
  int get coinsEarned => _friendsInvited * referralReward;

  UserModel? get _currentUser => _db.userModel;
  String get referralCode => _currentUser?.userId ?? '';

  /// Queries Firestore for users who used this user's referral code.
  Future<void> _fetchReferralStats() async {
    final userId = _currentUser?.userId;
    if (userId == null || userId.isEmpty) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('referred_by', isEqualTo: userId)
          .count()
          .get();
      _friendsInvited = snapshot.count ?? 0;
      notifyListeners();
    } catch (_) {
      // Silently fail — stats remain at 0.
    }
  }

  /// Validate, look up the referrer, and credit both users (1000 coins each).
  Future<void> validateReferralCode(BuildContext context) async {
    if (_isApplyingReferral) return;

    final user = _currentUser;
    if (user == null) {
      'Something went wrong. Try again.'.showErrorAlert();
      return;
    }

    if (user.isGuest) {
      'Please link your account first.'.showErrorAlert();
      return;
    }

    if (user.referredBy != null && user.referredBy!.isNotEmpty) {
      'You have already used a referral code.'.showInfoAlert();
      return;
    }

    final code = referralController.text.trim();
    if (code.isEmpty) {
      _errorText = 'Please enter a referral code.';
      notifyListeners();
      return;
    }

    if (code == user.userId) {
      _errorText = "You can't use your own referral code.";
      notifyListeners();
      "You can't use your own referral code.".showErrorAlert();
      return;
    }

    _errorText = null;
    _isApplyingReferral = true;
    notifyListeners();

    try {
      final referrerRef = _firestore.collection('users').doc(code);
      final selfRef = _firestore.collection('users').doc(user.userId);

      late double newSelfCoins;
      await _firestore.runTransaction((tx) async {
        final referrerSnap = await tx.get(referrerRef);
        if (!referrerSnap.exists) {
          throw _ScReferralException('Invalid referral code.');
        }

        final selfSnap = await tx.get(selfRef);
        if (!selfSnap.exists) {
          throw _ScReferralException('Something went wrong. Try again.');
        }

        final selfData = selfSnap.data()!;
        final referrerData = referrerSnap.data()!;

        final existingRef = selfData['referred_by'] as String?;
        if (existingRef != null && existingRef.isNotEmpty) {
          throw _ScReferralException('You have already used a referral code.');
        }

        final selfCoins = (selfData['coin'] as num).toDouble() + referralReward;
        final referrerCoins =
            (referrerData['coin'] as num).toDouble() + referralReward;
        newSelfCoins = selfCoins;

        tx.update(selfRef, {'referred_by': code, 'coin': selfCoins});
        tx.update(referrerRef, {'coin': referrerCoins});
      });

      // Reflect new state locally so the screen rebuilds.
      _db.userModel = user.copyWith(referredBy: code, coin: newSelfCoins);

      referralController.clear();
      // Refresh stats so "Friends Invited" / "Coins Earned" update immediately.
      unawaited(_fetchReferralStats());
      'Referral applied! You earned $referralReward coins.'.showSuccessAlert();
    } on _ScReferralException catch (e) {
      _errorText = e.message;
      e.message.showErrorAlert();
    } catch (e) {
      e.logE;
      _errorText = 'Could not apply referral.';
      'Could not apply referral.'.showErrorAlert();
    } finally {
      _isApplyingReferral = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    referralController.dispose();
    super.dispose();
  }
}

class _ScReferralException implements Exception {
  final String message;
  _ScReferralException(this.message);
}
