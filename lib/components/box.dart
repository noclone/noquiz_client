import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:provider/provider.dart';

class NQBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color borderColor;
  final double spreadRadius;
  const NQBox({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(8.0),
    required this.borderColor,
    this.spreadRadius = 5.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorManager = Provider.of<ColorManager>(context);
    return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colorManager.currentColors.primaryColor,
          border: Border.all(
            color: borderColor,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: borderColor.withAlpha(127),
              spreadRadius: spreadRadius,
              blurRadius: 7,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: child
    );
  }
}
