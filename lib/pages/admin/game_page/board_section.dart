import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../utils/board.dart';
import '../../../utils/preferences.dart';

class BoardSection extends StatefulWidget {
  final String roomId;
  final WebSocketChannel channel;

  const BoardSection({
    Key? key,
    required this.roomId,
    required this.channel,
  }) : super(key: key);

  @override
  _BoardSectionState createState() => _BoardSectionState();
}

class _BoardSectionState extends State<BoardSection> {
  List<Map<String, dynamic>> board = [];
  List<bool> imageVisibility = [];

  @override
  void initState() {
    super.initState();
    fetchBoard();
  }

  Future<void> fetchBoard() async {
    try {
      final serverIp = await getServerIpAddress();
      if (serverIp == null || serverIp.isEmpty) {
        return;
      }
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}/board'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          board = List<Map<String, dynamic>>.from(data);
          imageVisibility = List<bool>.filled(board.length, true);
        });
      } else {
        print('Failed to load board');
      }
    } catch (e) {
      print('Error fetching board: $e');
    }
  }

  void _showAnswerDialog(String answer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Answer'),
          content: Text(answer),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (board.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const int crossAxisCount = 4;
        int itemCount = board.length;
        double availableHeight = constraints.maxHeight * 0.9;
        double availableWidth = constraints.maxWidth;

        double itemWidth = (availableWidth - (crossAxisCount - 1) * 4) / crossAxisCount;
        double itemHeight = (availableHeight - (((itemCount / crossAxisCount).ceil() - 1) * 4)) / ((itemCount / crossAxisCount).ceil());

        return Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () {
                  widget.channel.sink.add(jsonEncode({
                    "display-board": board,
                    "image-visibility": imageVisibility,
                  }));
                },
              ),
            ),
            Expanded(
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
                  return Stack(
                    children: [
                      Container(
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
                      ),
                      Positioned(
                        bottom: 4.0,
                        right: 4.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.send, size: 20),
                              onPressed: () {
                                widget.channel.sink.add(jsonEncode({
                                  "new-question": board[index]['question'],
                                  "answer": board[index]['answer'],
                                  "expected_answer_type": board[index]['expected_answer_type'],
                                  "images": board[index]["images"],
                                }));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.lightbulb_circle_outlined, size: 20),
                              onPressed: () {
                                _showAnswerDialog(board[index]['answer']);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.lightbulb, size: 20),
                              onPressed: () {
                                widget.channel.sink.add(jsonEncode({
                                  "show-answer": true,
                                }));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                setState(() {
                                  imageVisibility[index] = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
