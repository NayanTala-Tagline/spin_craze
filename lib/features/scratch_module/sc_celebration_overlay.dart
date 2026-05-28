import 'package:confetti/confetti.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScCelebrationOverlay {
  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    required bool isBetterLuck,
    String? wonText,
  }) {
    return context.pushNamed(
      AppRoutes.celebrationOverlay,
      extra: {
        'icon': icon,
        'title': title,
        'subtitle': subtitle,
        'buttonText': buttonText,
        'onTap': onTap,
        'isBetterLuck': isBetterLuck,
        'wonText': wonText,
      },
    );
  }
}

class ScCelebrationOverlayContent extends StatefulWidget {
  const ScCelebrationOverlayContent({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
    required this.isBetterLuck,
    this.wonText,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;
  final bool isBetterLuck;
  final String? wonText;

  @override
  State<ScCelebrationOverlayContent> createState() =>
      ScCelebrationOverlayContentState();
}

class ScCelebrationOverlayContentState extends State<ScCelebrationOverlayContent>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    if (!widget.isBetterLuck) {
      _confettiController.play();
    }

    _scaleController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          /// Confetti
          if (!widget.isBetterLuck)
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 3.14 / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.3,
                  colors: const [
                    Color(0xFF4CAF50),
                    Color(0xFFFFEB3B),
                    Color(0xFFFF5722),
                    Color(0xFF2196F3),
                    Color(0xFFE91E63),
                  ],
                ),
              ),
            ),

          /// Content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.w32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Animated Icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      widget.isBetterLuck
                          ? Icons.sentiment_dissatisfied
                          : widget.icon,
                      size: AppSize.h120,
                      color: widget.isBetterLuck ? Colors.orange : Colors.amber,
                    ),
                  ),

                  SizedBox(height: AppSize.h32),

                  /// Title
                  Text(
                    widget.title,
                    style: context.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp28,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (widget.wonText != null && widget.wonText!.isNotEmpty) ...[
                    SizedBox(height: AppSize.h16),
                    Text(
                      widget.wonText!,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: AppSize.sp18,
                      ),
                    ),
                  ],

                  SizedBox(height: AppSize.h16),

                  /// Reward Box
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSize.w16,
                      vertical: AppSize.h10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSize.r16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.isBetterLuck)
                          Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: AppSize.h28,
                          ),
                        SizedBox(width: AppSize.w8),
                        Text(
                          widget.subtitle,
                          style: context.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontSize: AppSize.sp22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SizedBox(height: AppSize.h24),

                  // /// Button
                  // AppButton(
                  //   text: widget.buttonText,
                  //   onPressed: () {
                  //     widget.onTap();
                  //   },
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
