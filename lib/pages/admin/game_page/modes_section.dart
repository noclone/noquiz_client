import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'board_section.dart';
import 'right_order_section.dart';
import 'themes_section.dart';
import 'questions_section.dart';

class ModesSection extends StatefulWidget {
  final String roomId;
  final WebSocketChannel channel;

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
            length: 4,
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      QuestionsSection(roomId: widget.roomId, channel: widget.channel),
                      ThemesSection(roomId: widget.roomId, channel: widget.channel),
                      RightOrderSection(roomId: widget.roomId, channel: widget.channel),
                      BoardSection(roomId: widget.roomId, channel: widget.channel),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Questions'),
                    Tab(text: 'Themes'),
                    Tab(text: 'Right Order'),
                    Tab(text: 'Board'),
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
