import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../utils/board.dart';
import 'display_state.dart';

class BoardDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const BoardDisplay(
      {super.key,
      required this.setCurrentDisplayState,
      required this.broadcastStream});

  @override
  State<BoardDisplay> createState() => _BoardDisplayState();
}

class _BoardDisplayState extends State<BoardDisplay> {
  List<Map<String, dynamic>> board = [];
  List<bool> imageVisibility = [];

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('display-board')) {
        widget.setCurrentDisplayState(DisplayState.board);
        setState(() {
          board = List<Map<String, dynamic>>.from(data['display-board']);
          imageVisibility = List<bool>.from(data['image-visibility']);
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
    if (board.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const int crossAxisCount = 4;
            int itemCount = board.length;
            double availableHeight = constraints.maxHeight * 0.9;
            double availableWidth = constraints.maxWidth;

            double itemWidth =
                (availableWidth - (crossAxisCount - 1) * 4) / crossAxisCount;
            double itemHeight = (availableHeight -
                    (((itemCount / crossAxisCount).ceil() - 1) * 4)) /
                ((itemCount / crossAxisCount).ceil());

            return Center(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: itemWidth / itemHeight,
                children: List.generate(itemCount, (index) {
                  if (!imageVisibility[index]) {
                    return Container();
                  }
                  final thumbnailUrl = board[index]['thumbnail'];
                  return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: getBorderColor(board[index]['difficulty']),
                            width: 4.0,
                          ),
                        ),
                        child: Image.network(
                          thumbnailUrl,
                          fit: BoxFit.fill,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ));
                }),
              ),
            );
          },
        ));
  }
}
