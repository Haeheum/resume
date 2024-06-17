import 'package:flutter/material.dart';

enum LanguageOptions {
  korean('ko', '한글', AssetImage('assets/images/korea_flag.png')),
  english('en', 'English', AssetImage('assets/images/america_flag.png'));

  const LanguageOptions(this.code, this.label, this.image);

  final String code;
  final String label;
  final AssetImage image;
}