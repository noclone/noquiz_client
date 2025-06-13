import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../utils/server.dart';

class ScoresSection extends StatefulWidget {
  final List<Map<String, dynamic>> players;
  final String roomId;

  const ScoresSection({
    super.key,
    required this.players,
    required this.roomId,
  });

  @override
  State<ScoresSection> createState() => _ScoresSectionState();
}

class _ScoresSectionState extends State<ScoresSection> {
  Future<void> updatePlayerScore(int playerIndex) async {
    final player = widget.players[playerIndex];
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}/player/score'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'player_id': player['id'],
          'score': player['score'],
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to update player score: ${response.body}');
      }
    } catch (e) {
      print('Error updating player score: $e');
    }
  }

  void incrementScore(int index) {
    setState(() {
      widget.players[index]['score']++;
    });
    updatePlayerScore(index);
  }

  void decrementScore(int index) {
    setState(() {
      widget.players[index]['score']--;
    });
    updatePlayerScore(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.players.length,
        itemBuilder: (context, index) {
          final player = widget.players[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => incrementScore(index),
                ),
                Text(player['name']),
                Text('Score: ${player['score']}'),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => decrementScore(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
