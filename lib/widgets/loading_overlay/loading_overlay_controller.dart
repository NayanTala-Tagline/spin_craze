import 'package:flutter/foundation.dart' show immutable;

/// typedef for the loading overlay
typedef CloseLoadingPage = bool Function();

/// typedef for updating the loading overlay
typedef UpdateLoadingPage = bool Function(String text);

/// typedef for updating the progress
typedef UpdateProgressPage = bool Function(double? val);

/// controller for the loading overlay
@immutable
class LoadingOverlayController {
  /// constructor
  const LoadingOverlayController({
    required this.close,
    required this.update,
    required this.progress,
  });

  /// close the loading overlay
  final CloseLoadingPage close;

  /// update the loading overlay
  final UpdateLoadingPage update;

  /// update the progress overlay
  final UpdateProgressPage progress;
}
