import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';

import '../../../utils/visibility_component.dart';

enum RightOrderState {
  images,
  playerAnswers,
}

class RightOrderDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const RightOrderDisplay({
    Key? key,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  }) : super(key: key);

  @override
  _RightOrderDisplayState createState() => _RightOrderDisplayState();
}

class _RightOrderDisplayState extends State<RightOrderDisplay> {
  String? currentRightOrder;
  List<List<dynamic>> imageData = [];
  bool showLabels = false;
  RightOrderState state = RightOrderState.images;

  List<Map<String, dynamic>> playerAnswers = [];

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('right-order')) {
        setState(() {
          widget.setCurrentDisplayState(DisplayState.rightOrder);
          state = RightOrderState.images;
          currentRightOrder = data['right-order'];
          imageData = List<List<dynamic>>.from(data['data'] ?? [])..shuffle();
          showLabels = false;
        });
      } else if (data.containsKey('show-right-order-answer')) {
        setState(() {
          widget.setCurrentDisplayState(DisplayState.rightOrder);
          state = RightOrderState.images;
          currentRightOrder = data['show-right-order-answer'];
          imageData = List<List<dynamic>>.from(data['data'] ?? []);
          showLabels = true;
        });
      } else if (data.containsKey('player-right-order-answer')) {
        setState(() {
          state = RightOrderState.playerAnswers;
          playerAnswers.add({
            'imagesOrder': data['player-right-order-answer'],
            'playerName': data['player_name'],
          });
        });
      } else if (data.containsKey('send-right-order-answer')){
        setState(() {
          playerAnswers.clear();
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      buildComponent(
        visible: state == RightOrderState.images,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                currentRightOrder ?? '',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            if (imageData.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: SizedBox(
                      height: 250,
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: imageData.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 150,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      imageData[index][0],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                  if (showLabels)
                                    Text(
                                      imageData[index][1],
                                      style: const TextStyle(fontSize: 20),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      buildComponent(
        visible: state == RightOrderState.playerAnswers,
        child: ListView(
          shrinkWrap: true,
          children: playerAnswers.map((playerAnswer) {
            return Column(
              children: [
                Text(
                  playerAnswer['playerName'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Center(
                  child: SizedBox(
                    height: 150,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: playerAnswer['imagesOrder'].length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 150,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.network(
                                    playerAnswer['imagesOrder'][index][0],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ]);
  }
}
