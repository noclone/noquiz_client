import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/components/title_text.dart';
import 'package:noquiz_client/utils/colors.dart';
import 'package:provider/provider.dart';

class NQAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  const NQAppBar({
    Key? key,
    required this.title,
    this.actions = const [],
  }) : super(key: key);

  @override
  _NQAppBarState createState() => _NQAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NQAppBarState extends State<NQAppBar> {
  bool switchValue = false;

  @override
  Widget build(BuildContext context) {
    final colorManager = Provider.of<ColorManager>(context);

    List<Widget> updatedActions = List.from(widget.actions);
    updatedActions.add(
      Switch(
        activeColor: colorManager.currentColors.secondaryColor,
        activeTrackColor: colorManager.currentColors.secondaryColor.withAlpha(127),
        inactiveThumbColor: colorManager.currentColors.textPrimaryColor,
        inactiveTrackColor: colorManager.currentColors.textPrimaryColor.withAlpha(127),
        value: switchValue,
        onChanged: (value) {
          setState(() {
            switchValue = value;
          });
          colorManager.setColors(
            colorManager.currentColors == lightColors ? darkColors : lightColors,
          );
        },
      ),
    );

    return AppBar(
      title: NQTitleText(text: widget.title),
      backgroundColor: colorManager.currentColors.primaryColor,
      iconTheme: IconThemeData(color: colorManager.currentColors.tertiaryColor),
      actions: updatedActions,
    );
  }
}
