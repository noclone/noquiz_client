import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/colors.dart';

class NQTitleText extends StatelessWidget {
  final String text;
  final double? fontSize;

  const NQTitleText({
    Key? key,
    required this.text,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        shadows: [
          Shadow(
            color: secondaryColor,
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }
}