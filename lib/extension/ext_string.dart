// ignore_for_file: public_member_api_docs

import 'package:spin_craze/utils/logger.dart';
import 'package:intl/intl.dart';

/// extension for [String]
extension StringX on String {
  bool get hasEmoji => RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
  ).hasMatch(this);

  String get capitalized => this[0].toUpperCase() + substring(1);

  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String toTitleCase() => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.toCapitalized()).join(' ');

  String get removeMobileFormatter =>
      replaceAll('(', '').replaceAll(')', '').replaceAll(' ', '').trim();

  Uri? get uri => Uri.tryParse(this);

  bool get isValidNetworkURL =>
      (uri?.hasAbsolutePath ?? false) ||
      (uri?.scheme.startsWith('http') ?? false);

  DateTime? formatDateTimeToLocalDate({
    String inFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS",
    String outFormat = 'MM/dd/yy HH:mm',
  }) {
    try {
      final dateTime = DateFormat(inFormat).parse(this, true);
      return dateTime.toLocal();
    } catch (error) {
      '$error'.logD;
    }
    return null;
  }

  /// Returns a String without white space at all
  /// "hello world" // helloworld
  String get removeAllWhiteSpace => replaceAll(RegExp(r'\s+\b|\b\s'), '');

  String get upperCamelCase {
    final out = StringBuffer();
    final parts = split('_');
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        out.write(part.capitalized);
      }
    }
    return out.toString();
  }

  /// Returns a copy of this with [other] inserted starting at [index].
  ///
  /// Example:
  /// ```dart
  /// 'word'.insert('s', 0); // 'sword'
  /// 'word'.insert('ke', 3); // 'worked'
  /// 'word'.insert('y', 4); // 'wordy'
  /// ```
  String insert(String other, int index) =>
      (StringBuffer()
            ..write(substring(0, index))
            ..write(other)
            ..write(substring(index)))
          .toString();

  String getOrdinal() {
    final number = int.parse(this);
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }

    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  /// check value is empty or not if empty then return null ortherwise return value
  String? get nullCheck => isEmpty ? null : this;

  /// this function is use for add comma in string if it is not null or empty
  String addComma({bool isLast = false}) =>
      isEmpty ? '' : '$this${isLast ? '' : ', '}';

  /// this function is use top convert upper case to lower like = END_STOP_LOCATION => End Stop Location
  String upperToLower({bool isLast = false}) =>
      toLowerCase() // Convert to lowercase
          .split('_') // Split by underscore
          .map(
            (word) => word[0].toUpperCase() + word.substring(1),
          ) // Capitalize first letter
          .join(' ');

  /// this function is use for convert doublet to short like = END_STOP_LOCATION => End Stop Location
  String doubletToShort() => double.tryParse(this)?.toStringAsFixed(5) ?? this;

  /// ex: HELLO_UPPERCASE => Hello upercase
  String get upToLower => toLowerCase()
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  /// Formats number strings into:
  /// - Currency (with Western style commas) for ≤ 7 digits
  /// - Compact format (K, M, B) for > 7 digits
  String smartFormat({String currencySymbol = r'$'}) {
    final raw = replaceAll(RegExp(r'[^\d.]'), '');
    final value = double.tryParse(raw);
    if (value == null) return this;

    // Count only digits before decimal
    final digitCount = raw.split('.')[0].length;

    if (digitCount > 7) {
      // Compact format
      if (value >= 1e9) {
        return '${(value / 1e9).toStringAsFixed(1)}B';
      } else if (value >= 1e6) {
        return '${(value / 1e6).toStringAsFixed(1)}M';
      } else {
        return '${(value / 1e3).toStringAsFixed(1)}K';
      }
    } else {
      // Currency format with international (Western) style commas
      final formatter = NumberFormat.decimalPattern('en_US');
      return '$currencySymbol ${formatter.format(value)}';
    }
  }
}

extension StringExtension on num? {
  double? get twoDecimal =>
      this == null ? null : double.parse(this?.toStringAsFixed(2) ?? '0');
  bool get notZero => this != null && this != 0;
}
