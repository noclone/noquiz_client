import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/preferences.dart';

class PlayerList extends StatefulWidget {
  final List<Map<String, dynamic>> players;
  final Map<String, dynamic>? admin;

  const PlayerList({
    super.key,
    required this.players,
    this.admin,
  });

  @override
  State<PlayerList> createState() => _PlayerListState();
}

class _PlayerListState extends State<PlayerList> {
  String? playerId;

  @override
  void initState() {
    super.initState();

    getPlayerId().then((playerId) {
      setState(() {
        this.playerId = playerId;
      });
    });
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
                  title: Text(player['name']),
                  trailing: isCurrentPlayer
                      ? const Text(
                          '(You)',
                          style: TextStyle(color: Colors.blue),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
