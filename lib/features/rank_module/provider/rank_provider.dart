import 'dart:async';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../model/leaderboard_user_model.dart';

/// Duration of one leaderboard cycle.
const _kCycleDuration = Duration(minutes: 20);

class RankProvider extends ChangeNotifier {
  final _fireStore = FirebaseFirestore.instance;
  final _db = Injector.instance<AppDB>();

  bool isLoading = true;
  String? error;

  List<LeaderboardUser> top3 = [];
  List<LeaderboardUser> listUsers = [];

  int _remainingSeconds = 0;
  Timer? _timer;

  bool get canRefresh => _remainingSeconds == 0;

  RankProvider() {
    _initTimer();
    _fetchLeaderboard();
  }

  void _initTimer() {
    final stored = _db.leaderboardTimerExpiry;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (stored != null && stored > now) {
      _remainingSeconds = ((stored - now) / 1000).ceil();
    } else {
      _setFreshTimer();
      return;
    }
    _startTick();
  }

  void _setFreshTimer() {
    final expiry = DateTime.now().add(_kCycleDuration).millisecondsSinceEpoch;
    _db.leaderboardTimerExpiry = expiry;
    _remainingSeconds = _kCycleDuration.inSeconds;
    _startTick();
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        notifyListeners();
      }
    });
  }

  String get formattedTimer {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return '${h.toString().padLeft(2, '0')} : '
        '${m.toString().padLeft(2, '0')} : '
        '${s.toString().padLeft(2, '0')}';
  }

  /// Pull-to-refresh: only works when timer has expired. Triggers a one-time
  /// fetch (no live listener) so each refresh is a single Firestore read.
  Future<void> refresh() async {
    if (!canRefresh) return;
    isLoading = true;
    error = null;
    notifyListeners();

    await _fetchLeaderboard();

    _setFreshTimer();
  }

  /// One-time leaderboard read. Replaces the previous `.snapshots()` listener
  /// so the screen doesn't stream updates — data only loads on open and on a
  /// manual refresh, keeping Firestore reads to a minimum.
  Future<void> _fetchLeaderboard() async {
    try {
      final snapshot = await _fireStore
          .collection('users')
          .orderBy('coin', descending: true)
          .limit(25)
          .get();

      final all = snapshot.docs.map((doc) {
        final data = doc.data();
        final name = (data['name'] as String?) ?? 'Unknown';
        final coin = (data['coin'] as num?)?.toDouble() ?? 0;
        final level = (data['level'] as num?)?.toDouble() ?? 1;
        return LeaderboardUser(
          name,
          coin.toInt().toString(),
          level.toInt(),
        );
      }).where((u) => int.parse(u.coins) > 0).toList();

      top3 = all.take(3).toList();
      while (top3.length < 3) {
        top3.add(LeaderboardUser('—', '0', 1));
      }
      listUsers = all.length > 3 ? all.sublist(3) : [];
      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load leaderboard';
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
