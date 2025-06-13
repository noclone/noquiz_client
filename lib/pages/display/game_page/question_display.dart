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
  double questionFontSize = 40;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('new-question')) {
        setState(() {
          widget.setCurrentDisplayState(DisplayState.question);
          currentQuestion = data['new-question'];
          imageUrls = List<String>.from(data['images']);
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void increaseFontSize() {
    setState(() {
      questionFontSize += 2;
    });
  }

  void decreaseFontSize() {
    setState(() {
      questionFontSize = questionFontSize > 2 ? questionFontSize - 2 : questionFontSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = imageUrls.isEmpty ? 0.0 : screenWidth / imageUrls.length - 16.0 * imageUrls.length;

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                currentQuestion,
                style: TextStyle(fontSize: questionFontSize),
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
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: Column(
            children: [
              FloatingActionButton(
                onPressed: increaseFontSize,
                child: Icon(Icons.add),
                mini: true,
              ),
              SizedBox(height: 8),
              FloatingActionButton(
                onPressed: decreaseFontSize,
                child: Icon(Icons.remove),
                mini: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
