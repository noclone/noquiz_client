import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/colors.dart';

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
    return TextField(
      controller: controller,
      style: TextStyle(color: textPrimaryColor),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: textPrimaryColor),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textPrimaryColor),
        ),
      ),
      onSubmitted: (_) => onSubmitted != null ? onSubmitted!() : (),
      keyboardType: keyboardType,
      cursorColor: secondaryColor,
    );
  }
}