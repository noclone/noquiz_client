import 'dart:math';

import 'package:flutter/material.dart';
import 'package:noquiz_client/components/bordered_text.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/components/network_image.dart';
import 'package:noquiz_client/components/title_text.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/questions.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class QuestionDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;
  final Function showTimerOverlay;

  const QuestionDisplay({
    Key? key,
    required this.setCurrentDisplayState,
    required this.channel,
    required this.broadcastStream,
    required this.showTimerOverlay,
  }) : super(key: key);

  @override
  _QuestionDisplayState createState() => _QuestionDisplayState();
}

class _QuestionDisplayState extends State<QuestionDisplay> {
  String currentQuestion = 'Waiting for a question...';
  List<String> imageUrls = [];
  List<String> mcqOptions = [];
  String currentAnswer = '';
  int countdown = 0;
  bool showAnswer = false;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.QUESTION) {
        if (data.action == 'SEND') {
          widget.setCurrentDisplayState(DisplayState.question);
          setState(() {
            showAnswer = false;
            countdown = 3;
          });
          startCountdown(data.content);
        } else if (data.action == 'SHOW_ANSWER') {
          widget.showTimerOverlay(false);
          sendToSocket(widget.channel, MessageSubject.TIMER, "RESET", {});
          setState(() {
            showAnswer = true;
          });
        }
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void startCountdown(data) {
    Future.delayed(const Duration(seconds: 1), () {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
        startCountdown(data);
      } else {
        if (data['TIMER'] != 0) {
          widget.showTimerOverlay(true);
          sendToSocket(widget.channel, MessageSubject.TIMER, "START",
              {"DURATION": data['TIMER']});
        }

        setState(() {
          currentQuestion = data['QUESTION'];
          currentAnswer = data['ANSWER'] ?? '';
          imageUrls = List<String>.from(data['IMAGES']);
          mcqOptions = getMCQOptions(data['MCQ_OPTIONS']);
          countdown = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageWidth = imageUrls.isEmpty
        ? 0.0
        : screenWidth / imageUrls.length - 16.0 * imageUrls.length;
    final double questionFontSize =
        min(screenWidth * 0.05, screenHeight * 0.08);
    final double countdownFontSize = screenWidth * 0.1;
    final colorManager = Provider.of<ColorManager>(context);

    if (showAnswer && mcqOptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NQTitleText(
              text: currentAnswer.isNotEmpty
                  ? currentAnswer
                  : 'Answer not available.',
              fontSize: screenWidth * 0.05,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (countdown > 0 || currentQuestion.isNotEmpty)
          Center(
            child: SizedBox(
              width: screenWidth * 0.8,
              child: countdown > 0
                  ? NQBorderedText(
                      text: countdown.toString(),
                      fontSize: countdownFontSize,
                      padding: const EdgeInsets.all(40.0),
                      borderColor: colorManager.currentColors.secondaryColor,
                    )
                  : NQBorderedText(
                      text: currentQuestion,
                      fontSize: questionFontSize,
                      padding: const EdgeInsets.all(40.0),
                      borderColor: colorManager.currentColors.secondaryColor,
                    ),
            ),
          ),
        if (imageUrls.isNotEmpty && countdown == 0)
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SizedBox(
                  height: screenHeight * 0.6,
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
                                child: NQNetworkImage(
                                  imagePath: imageUrls[index],
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
        if (mcqOptions.isNotEmpty && countdown == 0)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: screenHeight * 0.2,
              width: screenWidth * 0.8,
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 10,
                children: List.generate(mcqOptions.length, (index) {
                  return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                          decoration: BoxDecoration(
                            color: colorManager.currentColors.primaryColor,
                            border: Border.all(
                              color: showAnswer &&
                                      mcqOptions[index] != currentAnswer
                                  ? Colors.red
                                  : colorManager.currentColors.secondaryColor,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: showAnswer &&
                                        mcqOptions[index] != currentAnswer
                                    ? Colors.red.withAlpha(127)
                                    : colorManager.currentColors.secondaryColor.withAlpha(127),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child:
                                showAnswer && mcqOptions[index] == currentAnswer
                                    ? NQTitleText(
                                        text: mcqOptions[index],
                                        fontSize: screenWidth * 0.02,
                                      )
                                    : Text(
                                        mcqOptions[index],
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.02,
                                          color: colorManager.currentColors.textPrimaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                          )));
                }),
              ),
            ),
          ),
      ],
    );
  }
}
