import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BuzzesSection extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const BuzzesSection({
    super.key,
    required this.channel,
    required this.broadcastStream,
  });

  @override
  State<BuzzesSection> createState() => _BuzzesSectionState();
}

class _BuzzesSectionState extends State<BuzzesSection> {
  List<Map<String, dynamic>> buzzes = [];

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('buzz')) {
        setState(() {
          buzzes.add({
            'name': data['buzz'][0],
            'time': data['buzz'][1],
          });
          buzzes.sort((a, b) => a['time'].compareTo(b['time']));
        });
      } else if (data.containsKey('reset-buzzer')){
        setState(() {
          buzzes.clear();
        });
      }
    });
  }

  void resetBuzzers() {
    setState(() {
      buzzes.clear();
    });
    widget.channel.sink.add(jsonEncode({"reset-buzzer": true}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: resetBuzzers,
            child: const Text('Reset Buzzers'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: buzzes.length,
              itemBuilder: (context, index) {
                final buzz = buzzes[index];
                return ListTile(
                  title: Text(buzz['name']),
                  subtitle: Text(buzz['time'].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
