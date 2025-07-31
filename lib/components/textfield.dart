import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:provider/provider.dart';

class NQTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final Function? onSubmitted;
  final TextInputType? keyboardType;

  const NQTextField({
    Key? key,
    required this.controller,
    this.labelText,
    this.onSubmitted,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorManager = Provider.of<ColorManager>(context);
    return TextField(
      controller: controller,
      style: TextStyle(color: colorManager.currentColors.textPrimaryColor),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: colorManager.currentColors.textPrimaryColor),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorManager.currentColors.secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorManager.currentColors.textPrimaryColor),
        ),
      ),
      onSubmitted: (_) => onSubmitted != null ? onSubmitted!() : (),
      keyboardType: keyboardType,
      cursorColor: colorManager.currentColors.secondaryColor,
    );
  }
}