import 'dart:async';

import 'package:spin_craze/shared/models/user_model.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Local storage for user data
class AppDB {
  AppDB._(this._box);

  static const _appDbBox = '_appDbBox';
  final Box<dynamic> _box;

  static Future<AppDB> getInstance() async {
    try {
      final box = await Hive.openBox<dynamic>(_appDbBox);
      return AppDB._(box);
    } catch (e) {
      final appDir = await getApplicationDocumentsDirectory();
      if (appDir.existsSync()) {
        appDir.deleteSync(recursive: true);
      }
      final box = await Hive.openBox<dynamic>(_appDbBox);
      return AppDB._(box);
    }
  }

  T getValue<T>(String key, {T? defaultValue}) =>
      _box.get(key, defaultValue: defaultValue) as T;

  Future<void> setValue<T>(String key, T value) => _box.put(key, value);

  // ==========================================================
  // USER MODEL
  // ==========================================================

  /// Notifies on user data changes
  Stream<BoxEvent> userListenable() {
    return _box.watch(key: 'userModel').asBroadcastStream();
  }

  UserModel? get userModel {
    final raw = getValue<Map<dynamic, dynamic>?>('userModel');
    if (raw == null) return null;
    return UserModel.fromLocalMap(Map<String, dynamic>.from(raw));
  }

  set userModel(UserModel? value) => setValue('userModel', value?.toLocalMap());

  // ==========================================================
  // INTERNET STATUS
  // ==========================================================

  set internetStatus(String status) => setValue('internetStatus', status);

  String get internetStatus =>
      getValue('internetStatus', defaultValue: 'connected');

  bool get isInternetConnected => internetStatus == 'connected';

  // ==========================================================
  // SELECTED LANGUAGE
  // ==========================================================

  /// Notifies on language changes so the app can rebuild with the new locale.
  Stream<BoxEvent> languageListenable() {
    return _box.watch(key: 'selectedLanguage').asBroadcastStream();
  }

  String? get selectedLanguage => getValue<String?>('selectedLanguage');

  set selectedLanguage(String? value) {
    if (value == null) {
      _box.delete('selectedLanguage');
    } else {
      setValue('selectedLanguage', value);
    }
  }

  // ==========================================================
  // LEADERBOARD TIMER
  // ==========================================================

  int? get leaderboardTimerExpiry =>
      getValue<int?>('leaderboardTimerExpiry');

  set leaderboardTimerExpiry(int? value) =>
      setValue('leaderboardTimerExpiry', value);

  // ==========================================================
  // LOGOUT
  // ==========================================================

  /// Removes user session data on logout.
  /// Preserves device-level keys like visit-website locks and leaderboard timer
  /// so they persist across logout/login cycles.
  Future<void> logoutUser() async {
    try {
      const preserved = {
        'leaderboardTimerExpiry',
        'internetStatus',
        'selectedLanguage',
      };
      final keysToDelete = _box.keys
          .where((k) {
            final key = k.toString();
            if (preserved.contains(key)) return false;
            if (key.startsWith('vw_lock_')) return false;
            return true;
          })
          .toList();
      await _box.deleteAll(keysToDelete);
    } catch (e) {
      e.logFatal;
    }
  }

  // ==========================================================
  // GENERAL
  // ==========================================================

  Future<void> clearData() async {
    try {
      await _box.clear();
    } catch (e) {
      e.logFatal;
    }
  }
}
