import 'dart:math';

import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/services/coin_service.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:flutter/material.dart';

// ── Question model ──────────────────────────────────────────────────────────

class _Question {
  const _Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
}

// ── Random question generators ──────────────────────────────────────────────

typedef _QuestionGenerator = _Question Function(Random rng);

/// Builds a question with shuffled options. Returns the [_Question] with
/// the correct answer placed at a random index.
_Question _buildQuestion(
  Random rng,
  String text,
  String correctAnswer,
  List<String> wrongAnswers,
) {
  final options = [correctAnswer, ...wrongAnswers]..shuffle(rng);
  return _Question(
    question: text,
    options: options,
    correctIndex: options.indexOf(correctAnswer),
  );
}

// 1. Multiplication of two 2-digit numbers
_Question _genMultiply(Random rng) {
  final a = 11 + rng.nextInt(19); // 11–29
  final b = 11 + rng.nextInt(9); // 11–19
  final correct = a * b;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(21) - 10);
    if (off != 0) wrongs.add('${correct + off}');
  }
  return _buildQuestion(rng, 'What is $a x $b?', '$correct', wrongs.toList());
}

// 2. Solve for x: x + a = b
_Question _genSolveAdd(Random rng) {
  final x = 10 + rng.nextInt(41); // 10–50
  final a = 10 + rng.nextInt(31); // 10–40
  final b = x + a;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(11) - 5);
    if (off != 0) wrongs.add('${x + off}');
  }
  return _buildQuestion(
    rng,
    'If x + $a = $b, what is x?',
    '$x',
    wrongs.toList(),
  );
}

// 3. Division (clean)
_Question _genDivide(Random rng) {
  final divisor = 6 + rng.nextInt(7); // 6–12
  final quotient = 8 + rng.nextInt(13); // 8–20
  final dividend = divisor * quotient;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(7) - 3);
    if (off != 0) wrongs.add('${quotient + off}');
  }
  return _buildQuestion(
    rng,
    'What is $dividend / $divisor?',
    '$quotient',
    wrongs.toList(),
  );
}

// 4. Percentage
_Question _genPercent(Random rng) {
  final pct = [15, 20, 25, 30, 35, 40, 45][rng.nextInt(7)];
  final whole = (4 + rng.nextInt(7)) * 20; // 80–200, multiples of 20
  final correct = (pct * whole) ~/ 100;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(21) - 10);
    if (off != 0 && correct + off > 0) wrongs.add('${correct + off}');
  }
  return _buildQuestion(
    rng,
    'What is $pct% of $whole?',
    '$correct',
    wrongs.toList(),
  );
}

// 5. Square root (perfect squares)
_Question _genSqrt(Random rng) {
  final root = 7 + rng.nextInt(12); // 7–18
  final square = root * root;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(5) - 2);
    if (off != 0) wrongs.add('${root + off}');
  }
  return _buildQuestion(
    rng,
    'What is the square root of $square?',
    '$root',
    wrongs.toList(),
  );
}

// 6. Order of operations: a x b - c + d
_Question _genOrderOps(Random rng) {
  final a = 3 + rng.nextInt(6); // 3–8
  final b = 4 + rng.nextInt(7); // 4–10
  final c = 5 + rng.nextInt(16); // 5–20
  final d = 2 + rng.nextInt(9); // 2–10
  final correct = a * b - c + d;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(11) - 5);
    if (off != 0) wrongs.add('${correct + off}');
  }
  return _buildQuestion(
    rng,
    'Solve: $a x $b - $c + $d = ?',
    '$correct',
    wrongs.toList(),
  );
}

// 7. Fraction of a number (1/4, 2/3, 3/4, 2/5, 3/5)
_Question _genFraction(Random rng) {
  final fractions = [(2, 3), (3, 4), (2, 5), (3, 5), (4, 5)];
  final frac = fractions[rng.nextInt(fractions.length)];
  // pick whole that divides cleanly
  final multiplier = 3 + rng.nextInt(8); // 3–10
  final whole = frac.$2 * multiplier * 10; // ensures clean division
  final correct = (frac.$1 * whole) ~/ frac.$2;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(21) - 10) * 5;
    if (off != 0 && correct + off > 0) wrongs.add('${correct + off}');
  }
  return _buildQuestion(
    rng,
    'What is ${frac.$1}/${frac.$2} of $whole?',
    '$correct',
    wrongs.toList(),
  );
}

// 8. Solve for y: a * y = b
_Question _genSolveMul(Random rng) {
  final y = 5 + rng.nextInt(36); // 5–40
  final a = 3 + rng.nextInt(8); // 3–10
  final b = a * y;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(11) - 5);
    if (off != 0) wrongs.add('${y + off}');
  }
  return _buildQuestion(
    rng,
    'If ${a}y = $b, what is y?',
    '$y',
    wrongs.toList(),
  );
}

// 9. Square minus constant: a² - c
_Question _genSquareMinus(Random rng) {
  final a = 12 + rng.nextInt(13); // 12–24
  final c = 50 + rng.nextInt(151); // 50–200
  final correct = a * a - c;
  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(21) - 10);
    if (off != 0) wrongs.add('${correct + off}');
  }
  final sup = '\u00B2'; // ² character
  return _buildQuestion(
    rng,
    'What is $a$sup - $c?',
    '$correct',
    wrongs.toList(),
  );
}

// 10. Decimal multiplication
_Question _genDecimal(Random rng) {
  final aInt = 15 + rng.nextInt(76); // 15–90 → 0.15–0.90
  final bInt = 10 + rng.nextInt(81); // 10–90 → 0.10–0.90
  final correctInt = aInt * bInt; // result x 10000
  // Format to 2–4 decimal places, trimming trailing zeros
  var correctStr = (correctInt / 10000).toStringAsFixed(4);
  correctStr = correctStr.replaceAll(RegExp(r'0+$'), '');
  if (correctStr.endsWith('.')) correctStr += '0';

  final aStr = (aInt / 100).toStringAsFixed(2);
  final bStr = (bInt / 100).toStringAsFixed(2);

  final wrongs = <String>{};
  while (wrongs.length < 3) {
    final off = (rng.nextInt(11) - 5) * 100; // shift by 0.01 increments
    if (off != 0) {
      var w = ((correctInt + off) / 10000).toStringAsFixed(4);
      w = w.replaceAll(RegExp(r'0+$'), '');
      if (w.endsWith('.')) w += '0';
      if (w != correctStr) wrongs.add(w);
    }
  }
  return _buildQuestion(
    rng,
    'What is $aStr x $bStr?',
    correctStr,
    wrongs.toList(),
  );
}

/// All generator functions — we pick 10 at random from these categories.
final _generators = <_QuestionGenerator>[
  _genMultiply,
  _genSolveAdd,
  _genDivide,
  _genPercent,
  _genSqrt,
  _genOrderOps,
  _genFraction,
  _genSolveMul,
  _genSquareMinus,
  _genDecimal,
];

/// Generates 10 randomised questions — one from each category, shuffled.
List<_Question> _generateQuestions() {
  final rng = Random();
  final questions = _generators.map((gen) => gen(rng)).toList()..shuffle(rng);
  return questions;
}

int get _coinsPerCorrect => RemoteConfigService.instance.quizPerQuestionReward;

// ── QuizScreen ──────────────────────────────────────────────────────────────

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<_Question> _questions = _generateQuestions();
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correctCount = 0;

  _Question get _current => _questions[_currentIndex];

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'quiz',
      screenClass: 'QuizScreen',
    );
    AnalyticsManager.instance.logEvent(
      name: 'quiz_started',
      parameters: {'total_questions': _questions.length},
    );
  }

  void _onOptionTap(int index) {
    if (_answered) return;
    final isCorrect = index == _current.correctIndex;
    AnalyticsManager.instance.logEvent(
      name: 'quiz_answer_selected',
      parameters: {
        'question_index': _currentIndex,
        'is_correct': isCorrect ? 1 : 0,
      },
    );
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (isCorrect) {
        _correctCount++;
      }
    });
    // Auto-advance after a short delay so user can see the result.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
          _answered = false;
        });
      } else {
        _showResultSheet();
      }
    });
  }

  void _showResultSheet() {
    final totalCoins = _correctCount * _coinsPerCorrect;
    final isLoss = totalCoins == 0;

    if (!mounted) return;

    AnalyticsManager.instance.logEvent(
      name: 'quiz_completed',
      parameters: {
        'score': _correctCount,
        'total': _questions.length,
        'coins': totalCoins,
        'is_loss': isLoss ? 1 : 0,
      },
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) => _ResultSheet(
        correctCount: _correctCount,
        totalQuestions: _questions.length,
        totalCoins: totalCoins,
        isLoss: isLoss,
        onClaim: () async {
          sheetCtx.pop();
          if (!isLoss) {
            AnalyticsManager.instance.logEvent(
              name: 'quiz_reward_claim_tap',
              parameters: {'coins': totalCoins},
            );
            final navCtx = rootNavKey.currentContext!;
            final earned = await RewardAdService.showMathQuiz(
              navCtx,
              defaultCoins: totalCoins,
            );
            if (earned == null) return;
            AnalyticsManager.instance.logEvent(
              name: 'quiz_reward_claimed',
              parameters: {'coins': earned},
            );
            await CoinService.addCoins(earned);
          }
          if (context.mounted) context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationHelper().handleBackPress(context);
      },
      child: CommonBackground(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEEF2F9), Color(0xFFEEF2F9)],
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CommonAppBar(title: context.l10n.quizTitle, showBack: true),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSize.h32),
                  _QuestionCard(question: _current.question),
                  SizedBox(height: AppSize.h32),
                  ..._current.options.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSize.h14),
                      child: _OptionTile(
                        text: entry.value,
                        index: entry.key,
                        selectedIndex: _selectedOption,
                        correctIndex: _answered ? _current.correctIndex : null,
                        onTap: () => _onOptionTap(entry.key),
                      ),
                    );
                  }),
                  const Spacer(),
                  _ProgressFooter(
                    current: _currentIndex + 1,
                    total: _questions.length,
                  ),
                  SizedBox(height: AppSize.h16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Progress footer ─────────────────────────────────────────────────────────

class _ProgressFooter extends StatelessWidget {
  const _ProgressFooter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.quizProgress(current, total),
          style: TextStyle(
            fontFamily: 'SFPro',
            color: const Color(0xFF0E1A2B),
            fontWeight: FontWeight.w600,
            fontSize: AppSize.sp14,
          ),
        ),
        SizedBox(height: AppSize.h10),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSize.r100),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: AppSize.h6,
            backgroundColor: const Color(0xFFDDE5F3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1164FF)),
          ),
        ),
      ],
    );
  }
}

// ── Question card ───────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        question,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'SFPro',
          color: const Color(0xFF0E1A2B),
          fontWeight: FontWeight.w700,
          fontSize: AppSize.sp18,
          height: 1.45,
        ),
      ),
    );
  }
}

// ── Option tile ─────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.onTap,
  });

  final String text;
  final int index;
  final int? selectedIndex;
  final int? correctIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final isCorrect = correctIndex == index;
    final isWrong = isSelected && correctIndex != null && !isCorrect;
    final isAnswered = correctIndex != null;

    Color borderColor;
    Color fillColor;
    Color textColor;

    if (isCorrect && isAnswered) {
      borderColor = const Color(0xFF22C55E);
      fillColor = const Color(0xFF22C55E);
      textColor = Colors.white;
    } else if (isWrong) {
      borderColor = const Color(0xFFEF4444);
      fillColor = const Color(0xFFEF4444);
      textColor = Colors.white;
    } else if (isSelected) {
      borderColor = const Color(0xFF1164FF);
      fillColor = const Color(0xFF1164FF);
      textColor = Colors.white;
    } else {
      borderColor = const Color(0xFFCFDDF7);
      fillColor = Colors.white;
      textColor = const Color(0xFF0E1A2B);
    }

    final radius = BorderRadius.circular(AppSize.r100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: isAnswered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w20,
            vertical: AppSize.h16,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: fillColor,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SFPro',
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: AppSize.sp15,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Result bottom sheet ─────────────────────────────────────────────────────

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.correctCount,
    required this.totalQuestions,
    required this.totalCoins,
    required this.isLoss,
    required this.onClaim,
  });

  final int correctCount;
  final int totalQuestions;
  final int totalCoins;
  final bool isLoss;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final colors = context.themeColors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSize.w24,
        AppSize.h20,
        AppSize.w24,
        AppSize.h32,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
          left: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
          right: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B7FF).withValues(alpha: 0.2),
            blurRadius: AppSize.r24,
            offset: Offset(0, -AppSize.h6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: AppSize.w40,
            height: AppSize.h4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.r100),
              color: textColors.muted,
            ),
          ),
          SizedBox(height: AppSize.h20),
          // Trophy
          Assets.images.scDailyRewardTrophy.image(
            height: AppSize.sp100,
            width: AppSize.sp100,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppSize.h20),
          Text(
            isLoss ? context.l10n.spinOops : context.l10n.spinCongrats,
            style: context.textTheme.titleLarge?.copyWith(
              color: isLoss ? const Color(0xFFFF5183) : const Color(0xFFFFD84D),
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp24,
            ),
          ),
          SizedBox(height: AppSize.h8),
          Text(
            isLoss
                ? context.l10n.spinBetterLuck
                : context.l10n.quizScore(correctCount, totalQuestions),
            style: context.textTheme.bodyLarge?.copyWith(
              color: textColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isLoss) ...[
            SizedBox(height: AppSize.h4),
            Text(
              context.l10n.spinWonCoins(totalCoins),
              style: context.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFFFD84D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: AppSize.h28),
          if (!isLoss)
            AdDisclaimerText(show: RewardAdService.isMathQuizAdEnabled),
          _PaleCyanPill(
            label: isLoss ? context.l10n.tryAgain : context.l10n.claimCoins,
            onPressed: onClaim,
          ),
        ],
      ),
    );
  }
}

// ── Reusable pale-cyan pill (same as spin module) ───────────────────────────

class _PaleCyanPill extends StatelessWidget {
  const _PaleCyanPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

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
          height: AppSize.h48,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9AE0FA), Color(0xFF5CCBF7)],
            ),
            border: Border.all(color: const Color(0xFFB8ECFF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5CCBF7).withValues(alpha: 0.4),
                blurRadius: AppSize.r16,
                offset: Offset(0, AppSize.h4),
              ),
            ],
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF003A52),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
