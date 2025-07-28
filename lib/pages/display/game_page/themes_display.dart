import 'package:flutter/material.dart';
import 'package:noquiz_client/components/bordered_text.dart';
import 'package:noquiz_client/components/title_text.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';

class ThemesDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const ThemesDisplay(
      {super.key,
      required this.setCurrentDisplayState,
      required this.broadcastStream});

  @override
  State<ThemesDisplay> createState() => _ThemesDisplayState();
}

class _ThemesDisplayState extends State<ThemesDisplay> {
  List<String> themes = [];

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.THEMES && data.action == 'SHOW') {
        setState(() {
          themes = List<String>.from(data.content['THEMES']);
        });
        widget.setCurrentDisplayState(DisplayState.themes);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 1;
    if (themes.length == 3 || themes.length == 4) {
      crossAxisCount = 2;
    } else if (themes.length > 4) {
      crossAxisCount = 3;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
            maxWidth: screenWidth * 0.8, maxHeight: screenHeight * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NQTitleText(
              text: 'Themes',
              fontSize: screenWidth * 0.03,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 3,
                children: themes.map<Widget>((theme) {
                  return Padding(
                      padding: const EdgeInsets.all(20),
                      child: NQBorderedText(
                          text: theme, fontSize: screenWidth * 0.04));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
