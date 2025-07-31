import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noquiz_client/components/board.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/utils/preferences.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

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
      final response = await http.get(
          Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}/board'));
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

  List<Widget> actions(int index, ColorManager colorManager){
    return [
      IconButton(
        color: colorManager.currentColors.secondaryColor,
        icon: const Icon(Icons.send, size: 20),
        onPressed: () {
          sendToSocket(widget.channel, MessageSubject.QUESTION, "SEND", {
            "QUESTION": board[index]['question'],
            "ANSWER": board[index]['answer'],
            "EXPECTED_ANSWER_TYPE": board[index]['expected_answer_type'],
            "IMAGES": board[index]["images"],
            "MCQ_OPTIONS": board[index]["mcq_options"],
            "TIMER": board[index]["timer"],
          });
        },
      ),
      IconButton(
        color: colorManager.currentColors.secondaryColor,
        icon: const Icon(Icons.lightbulb_circle_outlined, size: 20),
        onPressed: () {
          _showAnswerDialog(board[index]['answer']);
        },
      ),
      IconButton(
        color: colorManager.currentColors.secondaryColor,
        icon: const Icon(Icons.lightbulb, size: 20),
        onPressed: () {
          sendToSocket(
              widget.channel, MessageSubject.QUESTION, "SHOW_ANSWER", {});
        },
      ),
      IconButton(
        color: colorManager.currentColors.secondaryColor,
        icon: const Icon(Icons.delete, size: 20),
        onPressed: () {
          setState(() {
            imageVisibility[index] = false;
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (board.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return NQBoard(
      board: board,
      imageVisibility: imageVisibility,
      actions: actions,
    );
  }
}
