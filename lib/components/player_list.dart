import 'package:flutter/material.dart';

class PlayerList extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final Map<String, dynamic>? admin;

  const PlayerList({super.key, required this.players, this.admin});

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
            itemCount: players.length + (admin != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (admin != null && index == 0) {
                return ListTile(
                  title: Text('${admin!['name']} (Admin)'),
                );
              }
              final playerIndex = admin != null ? index - 1 : index;
              final player = players[playerIndex];
              return ListTile(
                title: Text(player['name']),
              );
            },
          ),
        ),
      ],
    );
  }
}
