import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class DisplayRoomGamePage extends StatefulWidget {
  final String roomId;

  const DisplayRoomGamePage({super.key, required this.roomId});

  @override
  State<DisplayRoomGamePage> createState() => _DisplayRoomGamePageState();
}

class _DisplayRoomGamePageState extends State<DisplayRoomGamePage> {
  late IOWebSocketChannel channel;
  String currentQuestion = 'Waiting for a question...';
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add(jsonEncode({"name": "display_${widget.roomId}", "display": true}));
    });

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('room-deleted')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin left the room')),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else if (data.containsKey('new-question')) {
        setState(() {
          currentQuestion = data['new-question'];
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
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
        _showPlayerScores();
      } else {
        print('Failed to load room state');
      }
    } catch (e) {
      print('Error fetching room state: $e');
    }
  }

  void _showPlayerScores() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
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
      },
    );
  }


  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Display Room: ${widget.roomId}'),
      ),
      body: Stack(
        children: [
          Center(
            child: Text(
              currentQuestion,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: fetchRoomState,
              child: const Icon(Icons.score),
            ),
          ),
        ],
      ),
    );
  }
}
