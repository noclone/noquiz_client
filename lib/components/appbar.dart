import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/components/title_text.dart';
import 'package:provider/provider.dart';

class NQAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  const NQAppBar({
    Key? key,
    required this.title,
    this.actions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorManager = Provider.of<ColorManager>(context);
    return AppBar(
      title: NQTitleText(text: title),
      backgroundColor: colorManager.currentColors.primaryColor,
      iconTheme: IconThemeData(color: colorManager.currentColors.tertiaryColor),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}