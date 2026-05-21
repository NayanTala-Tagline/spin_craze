import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class LoadingIndicator extends StatelessWidget {
  /// Constructor
  const LoadingIndicator({
    super.key,
    this.progress,
    this.color,
    this.strokeWidth = 4.0,
  }) : dimension = null;

  /// Named constructor
  /// [dimension] property required
  const LoadingIndicator.square({
    required this.dimension,
    super.key,
    this.progress,
    this.color,
    this.strokeWidth = 4.0,
  });

  /// Loading progress between 0 - 1
  final double? progress;

  /// Color of loading indicator
  final Color? color;

  /// The width of the line used to draw the circle.
  final double strokeWidth;

  /// For resize loading indicator
  final double? dimension;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.white),
        value: progress,
      ),
    );
  }
}
