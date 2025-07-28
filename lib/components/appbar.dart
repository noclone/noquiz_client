import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/colors.dart';

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
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          shadows: [
            Shadow(
              color: secondaryColor,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
      backgroundColor: primaryColor,
      iconTheme: IconThemeData(color: tertiaryColor),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}