import 'package:flutter/material.dart';
import 'package:test4/constant/appColor.dart';

class Font {
  Font._();

  static TextStyle h1 = const TextStyle(
      fontSize: 30, fontWeight: FontWeight.bold, color: AppColor.base);
  static TextStyle h2 = const TextStyle(
      fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.base);

  static TextStyle title = const TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.base);
  static TextStyle subtitle = const TextStyle(
      fontSize: 15, fontWeight: FontWeight.bold, color: AppColor.base);
  static TextStyle body = const TextStyle(
      fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.base);
}
