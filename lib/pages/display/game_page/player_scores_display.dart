import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlayerScoresDisplay extends StatefulWidget {
  final String roomId;

  const PlayerScoresDisplay({super.key, required this.roomId,});

  @override
  State<PlayerScoresDisplay> createState() => _PlayerScoresDisplayState();
}

class _PlayerScoresDisplayState extends State<PlayerScoresDisplay> {
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Player Scores',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
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
          ],
        ),
      ),
    );
  }
}
