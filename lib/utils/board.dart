import 'package:flutter/material.dart';

Color getBorderColor(String difficulty) {
  switch (difficulty) {
    case 'EASY':
      return Colors.green;
    case 'MEDIUM':
      return Colors.orange;
    case 'HARD':
      return Colors.red;
    default:
      return Colors.grey;
  }
}