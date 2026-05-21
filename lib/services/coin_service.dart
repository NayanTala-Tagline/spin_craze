import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoinService {
  CoinService._();

  static final _fireStore = FirebaseFirestore.instance;
  static final _db = Injector.instance<AppDB>();

  static Future<void> addCoins(int amount) async {
    final user = _db.userModel;
    if (user == null) return;

    final newCoin = user.coin + amount;
    final newXp = (newCoin / 10).roundToDouble();
    final newLevel = ((newXp / 200).floor() + 1).toDouble();

    _db.userModel = user.copyWith(coin: newCoin, xp: newXp, level: newLevel);

    try {
      await _fireStore.collection('users').doc(user.userId).update({
        'coin': newCoin,
        'xp': newXp,
        'level': newLevel,
      });
    } catch (e) {
      'CoinService.addCoins error: $e'.logD;
    }
  }
}
