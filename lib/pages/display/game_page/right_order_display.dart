import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/components/image_list.dart';
import 'package:noquiz_client/components/title_text.dart';
import 'package:noquiz_client/components/visibility_component.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/colors.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';

enum RightOrderState {
  images,
  playerAnswers,
}

class RightOrderDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const RightOrderDisplay({
    Key? key,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  }) : super(key: key);

  @override
  _RightOrderDisplayState createState() => _RightOrderDisplayState();
}

class _RightOrderDisplayState extends State<RightOrderDisplay> {
  String? rightOrderTitle;
  List<List<dynamic>> answerData = [];
  List<List<dynamic>> imageData = [];
  bool showAnswer = false;
  RightOrderState state = RightOrderState.images;
  List<Map<String, dynamic>> playerAnswers = [];

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.RIGHT_ORDER) {
        if (data.action == "SEND") {
          setState(() {
            widget.setCurrentDisplayState(DisplayState.rightOrder);
            state = RightOrderState.images;
            rightOrderTitle = data.content['TITLE'];
            answerData = List<List<dynamic>>.from(data.content['DATA'] ?? []);
            imageData = List<List<dynamic>>.from(data.content['DATA'] ?? [])
              ..shuffle();
            showAnswer = false;
          });
        } else if (data.action == "SHOW_ANSWER") {
          setState(() {
            widget.setCurrentDisplayState(DisplayState.rightOrder);
            state = RightOrderState.images;
            rightOrderTitle = data.content['TITLE'];
            answerData = List<List<dynamic>>.from(data.content['DATA'] ?? []);
            showAnswer = true;
          });
        } else if (data.action == "PLAYER_ANSWER") {
          setState(() {
            state = RightOrderState.playerAnswers;
            playerAnswers.add({
              'imagesOrder': data.content['VALUE'],
              'playerName': data.content['PLAYER_NAME'],
            });
          });
        } else if (data.action == "CLEAR_PLAYERS_ANSWER") {
          setState(() {
            playerAnswers.clear();
          });
        }
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  double responsiveFontSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.03;
  }

  @override
  Widget build(BuildContext context) {
    final colorManager = Provider.of<ColorManager>(context);
    return Stack(
      children: [
        visibility(
          visible: state == RightOrderState.images,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  textAlign: TextAlign.center,
                  rightOrderTitle ?? '',
                  style: TextStyle(
                    fontSize: responsiveFontSize(context),
                    fontWeight: FontWeight.bold,
                    color: colorManager.currentColors.textPrimaryColor,
                  ),
                ),
              ),
              if (imageData.isNotEmpty)
                NQImageList(
                  imageList: imageData,
                  answerList: showAnswer ? answerData : null,
                  showAnswer: showAnswer,
                  shadowText: !showAnswer,
                ),
            ],
          ),
        ),
        visibility(
          visible: state == RightOrderState.playerAnswers,
          child: Column(
            children: [
              if (answerData.isNotEmpty)
                Center(
                    child: Container(
                        margin: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: colorManager.currentColors.primaryColor,
                          border: Border.all(
                            color: colorManager.currentColors.secondaryColor,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: colorManager.currentColors.secondaryColor.withAlpha(127),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              NQTitleText(
                                text: 'Correct Answer',
                                fontSize: responsiveFontSize(context),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 2,
                                child: NQImageList(imageList: answerData),
                              ),
                            ],
                          ),
                        ))),
              Expanded(
                child: ListView.builder(
                  itemCount: playerAnswers.length,
                  itemBuilder: (context, index) {
                    final playerAnswer = playerAnswers[index];
                    List<List<dynamic>> imageData = List<List<dynamic>>.from(playerAnswer['imagesOrder'] ?? []);
                    return Column(
                      children: [
                        NQTitleText(text: playerAnswer['playerName'], fontSize: responsiveFontSize(context),),
                        NQImageList(imageList: imageData, answerList: answerData, colorTextAnswer: true,),
                        Container(
                          margin: const EdgeInsets.all(16.0),
                          height: 10,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withAlpha(127),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.white,
                                    Colors.blue.shade400,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
