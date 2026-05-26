import 'package:flutter/cupertino.dart';

class WalletCategory {
  final String title;
  final List<WalletItem> items;

  WalletCategory({required this.title, required this.items});
}

class WalletItem {
  final String title;
  final Widget icon;
  final Color color;
  final FormData formData;

  WalletItem(this.title, this.icon, this.color, this.formData);
}

class FormData {
  final String title;
  final Widget icon;
  final String regex;

  FormData(this.title, this.icon, this.regex);
}
