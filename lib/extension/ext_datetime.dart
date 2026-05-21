import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extension on [DateTime] class
extension DateTimeX on DateTime {
  /// to check if date is today
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// to check if date is today
  bool isToday() {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  /// to check if date is yesterday
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }

  /// to check if date is yesterday
  bool isExclusiveDay3() {
    final now = DateTime.now();
    final exclusive = DateTime(now.year, now.month, now.day + 3);
    return exclusive.day == day &&
        exclusive.month == month &&
        exclusive.year == year;
  }

  /// Set Time of day
  DateTime setTimeOfDay(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }

  /// Time of dat from date time
  TimeOfDay get time => TimeOfDay.fromDateTime(toLocal());

  /// get separator date string from date e.g Mon,6 May
  // String get separatorDate {
  //   if (isToday()) {
  //     return rootNavKey.currentContext!.l10n.today;
  //   } else if (isYesterday()) {
  //     return rootNavKey.currentContext!.l10n.yesterday;
  //   } else {
  //     return DateFormat('EE, d MMM yyyy').format(toLocal());
  //   }
  // }

  /// get full date time string from date e.g 23/10/2023, 09:32:00 PM
  String get fullDateTime =>
      DateFormat('dd/MM/yyyy, hh:mm:ss aa').format(toLocal());

  /// get full date time string from date e.g 23/10/2023
  String get dateFormate => DateFormat('dd/MM/yyyy').format(toLocal());

  /// get full date time string from date e.g 2023-10-20
  String get passDateFormateWithTime => toIso8601String();

  /// get full date time string from date e.g 2023-10-20
  String get passDateFormate => DateFormat('yyyy-MM-dd').format(this);

  /// get full date time string from date e.g Nov 21
  String get monthDateFormate => DateFormat('MMM dd').format(toLocal());

  /// get full date time string from date e.g 23/10/2023, 09:32:00 PM
  String get mmmDdYyyy => DateFormat('MMM dd, yyyy').format(toLocal());

  String get timeOnly => DateFormat('hh:mm aa').format(toLocal());
}
