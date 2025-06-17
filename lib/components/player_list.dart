import 'dart:convert';

import 'package:flutter/material.dart';

class PlayerList extends StatefulWidget {
  final Stream<dynamic> broadcastStream;
  final List<Map<String, dynamic>> players;
  final Map<String, dynamic>? admin;
  final Function(String)? onPlayerNameUpdated;

  const PlayerList({
    super.key,
    required this.broadcastStream,
    required this.players,
    this.admin,
    this.onPlayerNameUpdated,
  });

  @override
  State<PlayerList> createState() => _PlayerListState();
}

class _PlayerListState extends State<PlayerList> {
  final _controller = TextEditingController();
  String playerId = '';

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('players') && data.containsKey('player_id')) {
        setState(() {
          playerId = data['player_id'];
          _controller.text = data['player_name'];
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Players',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: widget.players.length + (widget.admin != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (widget.admin != null && index == 0) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(widget.admin!['name']),
                    trailing: const Text(
                      '(Admin)',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              final playerIndex = widget.admin != null ? index - 1 : index;
              final player = widget.players[playerIndex];
              final isCurrentPlayer = player['id'] == playerId;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: isCurrentPlayer
                      ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          onSubmitted: (newName) {
                            widget.onPlayerNameUpdated!(newName);
                          },
                        ),
                      ),
                      const Text(
                        '(You)',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  )
                      : Text(player['name']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
