import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.style,
  });

  final String text;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = GoogleFonts.notoNaskhArabic(
      textStyle: style ?? Theme.of(context).textTheme.titleLarge,
      height: 1.6,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: textAlign ?? TextAlign.right,
        maxLines: maxLines,
        overflow: overflow,
        style: resolvedStyle,
      ),
    );
  }
}
