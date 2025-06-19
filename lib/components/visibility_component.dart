import 'package:flutter/material.dart';

Widget buildComponent({required bool visible, required Widget child}) {
  return Visibility(
    visible: visible,
    maintainState: true,
    maintainAnimation: true,
    maintainSize: true,
    child: child,
  );
}