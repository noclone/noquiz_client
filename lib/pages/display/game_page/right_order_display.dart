import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';


class RightOrderDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const RightOrderDisplay({Key? key,
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

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('right-order')) {
        setState(() {
          widget.setCurrentDisplayState(DisplayState.rightOrder);
          currentRightOrder = data['right-order'];
          imageData = List<List<dynamic>>.from(data['data'] ?? [])..shuffle();
          showLabels = false;
        });
      } else if (data.containsKey('show-right-order-answer')) {
        setState(() {
          widget.setCurrentDisplayState(DisplayState.rightOrder);
          currentRightOrder = data['show-right-order-answer'];
          imageData = List<List<dynamic>>.from(data['data'] ?? []);
          showLabels = true;
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            currentRightOrder ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (imageData.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              double imageWidth = constraints.maxWidth / imageData.length - 16;

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
                          width: imageWidth,
                          child: Column(
                            children: [
                              Image.network(
                                imageData[index][0],
                                fit: BoxFit.contain,
                                height: 200,
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
    );
  }
}
