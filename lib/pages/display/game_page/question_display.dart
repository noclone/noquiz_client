import 'dart:convert';

import 'package:flutter/material.dart';

import 'display_state.dart';

class QuestionDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const QuestionDisplay({
    Key? key,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  }) : super(key: key);

  @override
  _QuestionDisplayState createState() => _QuestionDisplayState();
}

class _QuestionDisplayState extends State<QuestionDisplay> {
  String currentQuestion = 'Waiting for a question...';
  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('new-question')) {
        setState(() {
          widget.setCurrentDisplayState(DisplayState.question);
          currentQuestion = data['new-question'];
          imageUrls = List<String>.from(data['images'] ?? []);
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = imageUrls.isEmpty ? 0.0 : screenWidth / imageUrls.length - 16.0 * imageUrls.length;

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              currentQuestion,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
          if (imageUrls.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SizedBox(
                    height: 250,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: imageWidth,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.network(
                                    imageUrls[index],
                                    fit: BoxFit.scaleDown,
                                    width: double.infinity,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
    );
  }

}

