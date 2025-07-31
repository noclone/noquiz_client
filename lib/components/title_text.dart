import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/utils/colors.dart';
import 'package:provider/provider.dart';

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
    final colorManager = Provider.of<ColorManager>(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: colorManager.currentColors.textPrimaryColor,
        shadows: [
          Shadow(
            color: colorManager.currentColors.secondaryColor,
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }
}