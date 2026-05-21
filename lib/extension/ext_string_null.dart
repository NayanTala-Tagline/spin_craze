// ignore_for_file: public_member_api_docs

import 'package:intl/intl.dart';
// import 'package:sound_it/l10n/l10n.dart';
// import 'package:sound_it/routes/app_router.dart';

/// extension for [String]?
extension StringNullX on String? {
  /// checked string is not null and is not empty
  bool get isNotEmptyAndNotNull => this != null && this!.isNotEmpty;

  Uri? get uri => Uri.tryParse(this ?? '');

  bool get isValidNetworkURL => (uri?.hasAbsolutePath ?? false) || (uri?.scheme.startsWith('http') ?? false);

  /// Returns `true` if the String is either null or empty.
  bool get isEmptyOrNull => this?.isEmpty ?? true;

  String? convertToAgo({
    String inFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS",
    String text = '',
  }) {
    if (this != null) {
      try {
        final input = DateFormat(inFormat).parse(this!, true);
        final diff = DateTime.now().difference(input);
        if (diff.inDays > 365) {
          return '${(diff.inDays / 365).floor()}y${diff.inDays == 1 ? '' : ''} $text';
        } else if (diff.inDays > 7) {
          return '${(diff.inDays / 7).floor()}w${diff.inDays == 1 ? '' : ''} $text';
        } else if (diff.inDays >= 1) {
          return '${diff.inDays}d${diff.inDays == 1 ? '' : ''} $text';
        } else if (diff.inHours >= 1) {
          return '${diff.inHours}h${diff.inHours == 1 ? '' : ''} $text';
        } else if (diff.inMinutes >= 1) {
          return '${diff.inMinutes}min${diff.inMinutes == 1 ? '' : ''} $text';
        } else if (diff.inSeconds >= 1) {
          return '${diff.inSeconds}sec${diff.inSeconds == 1 ? '' : ''} $text';
        } else {
          return 'justNow';
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? convertToAgoWithTimeStamp({String? text = ''}) {
    if (this != null) {
      final input = DateTime.fromMillisecondsSinceEpoch(
        int.parse(this ?? ''),
      );

      final diff = DateTime.now().difference(input);
      if (diff.inDays > 365) {
        return '${(diff.inDays / 365).floor()}y${diff.inDays == 1 ? '' : ''} $text';
      } else if (diff.inDays > 7) {
        return '${(diff.inDays / 7).floor()}w${diff.inDays == 1 ? '' : ''} $text';
      } else if (diff.inDays >= 1) {
        return '${diff.inDays}d${diff.inDays == 1 ? '' : ''} $text';
      } else if (diff.inHours >= 1) {
        return '${diff.inHours}h${diff.inHours == 1 ? '' : ''} $text';
      } else if (diff.inMinutes >= 1) {
        return '${diff.inMinutes}min${diff.inMinutes == 1 ? '' : ''} $text';
      } else if (diff.inSeconds >= 1) {
        return '${diff.inSeconds}sec${diff.inSeconds == 1 ? '' : ''} $text';
      } else {
        return 'justNow';
      }
    }
    return null;
  }
}
