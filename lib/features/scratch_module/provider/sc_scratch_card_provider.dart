import 'dart:math';

import 'package:spin_craze/utils/remote_config.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';

class ScScratchCardProvider extends ChangeNotifier {
  ScScratchCardProvider() {
    _generateReward();
    controller = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  final GlobalKey<ScratcherState> scratchKey = GlobalKey<ScratcherState>();
  late ConfettiController controller;
  bool isThresholdReached = false;
  bool isGiftBoxRevealed = false;
  bool isGiftBoxOpened = false;

  int? reward;

  /// Reward between [scrachMinReward] and [scrachMaxReward] coins (from remote config).
  void _generateReward() {
    final min = RemoteConfigService.instance.scrachMinReward;
    final max = RemoteConfigService.instance.scrachMaxReward;
    final span = (max - min).abs() + 1;
    reward = min + Random().nextInt(span);
    notifyListeners();
  }

  void revealGiftBox() {
    isGiftBoxRevealed = true;
    notifyListeners();
  }

  void openGiftBox() {
    isGiftBoxOpened = true;
    notifyListeners();
  }

  void resetGame() {
    isThresholdReached = false;
    isGiftBoxRevealed = false;
    isGiftBoxOpened = false;
    _generateReward();
  }
}
