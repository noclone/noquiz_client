import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/colors.dart';

class ColorManager with ChangeNotifier {
  AppColors _currentColors = darkColors;

  AppColors get currentColors => _currentColors;

  void setColors(AppColors colors) {
    _currentColors = colors;
    notifyListeners();
  }
}
