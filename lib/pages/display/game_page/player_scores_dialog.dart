import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlayerScoresDialog extends StatefulWidget {
  final String roomId;

  const PlayerScoresDialog({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  _PlayerScoresDialogState createState() => _PlayerScoresDialogState();
}

class _PlayerScoresDialogState extends State<PlayerScoresDialog> {
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    fetchRoomState();
  }

  Future<void> fetchRoomState() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/rooms/${widget.roomId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          players = List<Map<String, dynamic>>.from(data['players']);
          players.sort((a, b) => b['score'].compareTo(a['score']));
        });
      } else {
        print('Failed to load room state');
      }
    } catch (e) {
      print('Error fetching room state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Player Scores'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    player['name'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    player['score'].toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
