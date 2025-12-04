import 'package:flutter/widgets.dart';

class Satoshi {
  static const String _fontFamily = 'Satoshi';

  /// Base font helper
  static TextStyle font({
    FontWeight? fontWeight,
    FontStyle? style,
    double? fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: fontWeight,
      fontStyle: style,
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      package: null,
    );
  }

  // ------- Predefined fontWeights like GoogleFonts ---------

  static TextStyle light({double? fontSize, Color? color}) =>
      font(fontWeight: FontWeight.w300, fontSize: fontSize, color: color);

  static TextStyle regular({double? fontSize, Color? color}) =>
      font(fontWeight: FontWeight.w400, fontSize: fontSize, color: color);

  static TextStyle medium({double? fontSize, Color? color}) =>
      font(fontWeight: FontWeight.w500, fontSize: fontSize, color: color);

  static TextStyle bold({double? fontSize, Color? color}) =>
      font(fontWeight: FontWeight.w700, fontSize: fontSize, color: color);

  static TextStyle black({double? fontSize, Color? color}) =>
      font(fontWeight: FontWeight.w900, fontSize: fontSize, color: color);

  // -------- Italics ---------

  static TextStyle lightItalic({double? fontSize, Color? color}) => font(
    fontWeight: FontWeight.w300,
    style: FontStyle.italic,
    fontSize: fontSize,
    color: color,
  );

  static TextStyle italic({double? fontSize, Color? color}) => font(
    fontWeight: FontWeight.w400,
    style: FontStyle.italic,
    fontSize: fontSize,
    color: color,
  );

  static TextStyle mediumItalic({double? fontSize, Color? color}) => font(
    fontWeight: FontWeight.w500,
    style: FontStyle.italic,
    fontSize: fontSize,
    color: color,
  );

  static TextStyle boldItalic({double? fontSize, Color? color}) => font(
    fontWeight: FontWeight.w700,
    style: FontStyle.italic,
    fontSize: fontSize,
    color: color,
  );

  static TextStyle blackItalic({double? fontSize, Color? color}) => font(
    fontWeight: FontWeight.w900,
    style: FontStyle.italic,
    fontSize: fontSize,
    color: color,
  );
}
