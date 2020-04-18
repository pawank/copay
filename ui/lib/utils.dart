import 'dart:ui';

import 'package:flutter/material.dart';

int getColorHexFromStr(String colorStr) {
  colorStr = 'FF' + colorStr;
  colorStr = colorStr.replaceAll('#', '');
  int val = 0;
  final int len = colorStr.length;
  for (int i = 0; i < len; i++) {
    final int hexDigit = colorStr.codeUnitAt(i);
    if (hexDigit >= 48 && hexDigit <= 57) {
      val += (hexDigit - 48) * (1 << (4 * (len - 1 - i)));
    } else if (hexDigit >= 65 && hexDigit <= 70) {
      // A..F
      val += (hexDigit - 55) * (1 << (4 * (len - 1 - i)));
    } else if (hexDigit >= 97 && hexDigit <= 102) {
      // a..f
      val += (hexDigit - 87) * (1 << (4 * (len - 1 - i)));
    } else {
      throw FormatException('An error occurred when converting a color');
    }
  }
  return val;
}

Map<int, Color> color = {
  50: Color.fromRGBO(255, 153, 51, .1),
  100: Color.fromRGBO(255, 153, 51, .2),
  200: Color.fromRGBO(255, 153, 51, .3),
  300: Color.fromRGBO(255, 153, 51, .4),
  400: Color.fromRGBO(255, 153, 51, .5),
  500: Color.fromRGBO(255, 153, 51, .6),
  600: Color.fromRGBO(255, 153, 51, .7),
  700: Color.fromRGBO(255, 153, 51, .8),
  800: Color.fromRGBO(255, 153, 51, .9),
  900: Color.fromRGBO(255, 153, 51, 1),
};

MaterialColor getMaterialColor(String hexColor) {
  if ((hexColor == null) || (hexColor.isEmpty)) {
    hexColor = '0xFF9933';
  } else {
    hexColor = hexColor.replaceAll('#', '0xFF');
  }
  final MaterialColor colorCustom = MaterialColor(0xFFFF9933, color);
  return colorCustom;
}
