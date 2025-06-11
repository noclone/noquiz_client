import 'package:flutter/material.dart';
import 'dart:async';

class QuestionDisplay extends StatefulWidget {
  final String question;
  final String? imageUrl;

  const QuestionDisplay({
    Key? key,
    required this.question,
    this.imageUrl,
  }) : super(key: key);

  @override
  _QuestionDisplayState createState() => _QuestionDisplayState();
}

class _QuestionDisplayState extends State<QuestionDisplay> {

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            widget.question,
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.network(widget.imageUrl!),
          ),
      ],
    );
  }
}
