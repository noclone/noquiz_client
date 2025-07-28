import 'package:flutter/material.dart';

Widget visibility({required bool visible, required Widget child}) {
  return Visibility(
    visible: visible,
    maintainState: true,
    maintainAnimation: true,
    maintainSize: true,
    child: child,
  );
}