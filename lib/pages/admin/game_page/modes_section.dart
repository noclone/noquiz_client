import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'themes_section.dart';
import 'questions_section.dart';

class ModesSection extends StatefulWidget {
  final String roomId;
  final IOWebSocketChannel channel;

  const ModesSection({
    Key? key,
    required this.roomId,
    required this.channel,
  }) : super(key: key);

  @override
  _ModesSectionState createState() => _ModesSectionState();
}

class _ModesSectionState extends State<ModesSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      QuestionsSection(roomId: widget.roomId, channel: widget.channel),
                      ThemesSection(roomId: widget.roomId, channel: widget.channel),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Questions'),
                    Tab(text: 'Themes'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
