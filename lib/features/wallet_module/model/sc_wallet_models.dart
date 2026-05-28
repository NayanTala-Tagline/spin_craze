import 'package:flutter/cupertino.dart';

class ScWalletCategory {
  final String title;
  final List<ScWalletItem> items;

  ScWalletCategory({required this.title, required this.items});
}

class ScWalletItem {
  final String title;
  final Widget icon;
  final Color color;
  final ScFormData formData;

  ScWalletItem(this.title, this.icon, this.color, this.formData);
}

class ScFormData {
  final String title;
  final Widget icon;
  final String regex;

  ScFormData(this.title, this.icon, this.regex);
}
