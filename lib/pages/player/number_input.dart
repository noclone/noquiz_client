import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/components/textfield.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';
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
    final colorManager = Provider.of<ColorManager>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Enter a number:',
          style: TextStyle(fontSize: 18, color: colorManager.currentColors.textPrimaryColor),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: NQTextField(controller: _numberController, labelText: 'Answer', keyboardType: TextInputType.number,),
        ),
        ElevatedButton(
          onPressed: _submitNumber,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
