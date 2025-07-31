import 'package:flutter/material.dart';
import 'package:noquiz_client/components/box.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:provider/provider.dart';

class NQBorderedText extends StatelessWidget {
  final String text;
  final String? subtext;
  final double? fontSize;
  final EdgeInsets? padding;
  final Color borderColor;

  const NQBorderedText({
    Key? key,
    required this.text,
    this.subtext,
    this.fontSize,
    this.padding = const EdgeInsets.all(8.0),
    required this.borderColor,
  }) : super(key: key);

  Widget getText(ColorManager colorManager) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: colorManager.currentColors.textPrimaryColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorManager = Provider.of<ColorManager>(context);

    return NQBox(
      padding: padding,
      borderColor: borderColor,
      child: Center(
        child: subtext == null
            ? getText(colorManager)
            : Column(
                children: [
                  getText(colorManager),
                  Text(
                    subtext!,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: colorManager.currentColors.textPrimaryColor,
                      shadows: [
                        Shadow(
                          color: colorManager.currentColors.secondaryColor,
                          blurRadius: 10,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
      ),
    );
  }
}
