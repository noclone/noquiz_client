import 'package:flutter/material.dart';
import 'package:noquiz_client/components/box.dart';
import 'package:noquiz_client/utils/colors.dart';

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
    this.borderColor = secondaryColor,
  }) : super(key: key);

  Widget getText() {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: textPrimaryColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NQBox(
      padding: padding,
      borderColor: borderColor,
      child: Center(
        child: subtext == null
            ? getText()
            : Column(
                children: [
                  getText(),
                  Text(
                    subtext!,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: textPrimaryColor,
                      shadows: const [
                        Shadow(
                          color: secondaryColor,
                          blurRadius: 10,
                          offset: Offset(2, 2),
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
