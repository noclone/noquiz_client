import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NumberInputComponent extends StatefulWidget {
  final WebSocketChannel channel;

  const NumberInputComponent({super.key, required this.channel});

  @override
  State<NumberInputComponent> createState() => _NumberInputComponentState();
}

class _NumberInputComponentState extends State<NumberInputComponent> {
  final TextEditingController _numberController = TextEditingController();

  void _submitNumber() {
    final number = _numberController.text;
    if (number.isNotEmpty) {
      sendToSocket(widget.channel, MessageSubject.PLAYER_ANSWER, "UPDATE", {"VALUE": number});
      _numberController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer sent')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Answer',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _submitNumber,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
