import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Animated page indicator dots.
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final Color? activeColor;
  final Color? inactiveColor;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = currentPage == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 16 : 8,
            height: 8,
            decoration: isActive
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: activeColor != null
                        ? null
                        : const LinearGradient(
                            colors: [
                              Color(0x90A86CFF),
                              Color(0xFF29B0E6),
                              Color(0xFF00B7FF),
                              Color(0xF865D3FF),
                            ],
                          ),
                    color: activeColor,
                  )
                : BoxDecoration(
                    shape: BoxShape.circle,
                    color: inactiveColor ?? const Color.fromARGB(255, 236, 241, 243),
                  ),
          ),
        );
      }),
    );
  }
}
