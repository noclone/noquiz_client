import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'display_state.dart';
import 'question_display.dart';
import 'player_scores_display.dart';
import 'player_answers_display.dart';
import 'right_order_display.dart';
import 'themes_display.dart';
import 'theme_answers_display.dart';
import 'answer_display.dart';
import 'timer_display.dart';

class DisplayRoomGamePage extends StatefulWidget {
  final String roomId;

  const DisplayRoomGamePage({super.key, required this.roomId});

  @override
  State<DisplayRoomGamePage> createState() => _DisplayRoomGamePageState();
}

class _DisplayRoomGamePageState extends State<DisplayRoomGamePage> {
  late IOWebSocketChannel channel;
  String currentQuestion = 'Waiting for a question...';
  String currentAnswer = '';
  String? imageUrl;
  List<String> themes = [];
  List<dynamic> themeAnswers = [];
  late Stream<dynamic> broadcastStream;
  DisplayState currentDisplayState = DisplayState.question;
  Timer? countdownTimer;
  int remainingTime = 0;
  String? currentRightOrder;
  List<List<dynamic>> imageData = [];
  bool showLabels = false;

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add(jsonEncode({"name": "display_${widget.roomId}", "display": true}));
    });

    broadcastStream = channel.stream.asBroadcastStream();
    broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('room-deleted')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin left the room')),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else if (data.containsKey('new-question')) {
        setState(() {
          currentQuestion = data['new-question'];
          currentAnswer = data['answer'] ?? '';
          imageUrl = data['image'];
          currentDisplayState = DisplayState.question;
        });
      } else if (data.containsKey('show-themes')) {
        setState(() {
          themes = List<String>.from(data['show-themes']);
          currentDisplayState = DisplayState.themes;
        });
      } else if (data.containsKey('theme-answers')) {
        setState(() {
          themeAnswers = data['theme-answers'];
          currentDisplayState = DisplayState.themeAnswers;
        });
      } else if (data.containsKey('show-players-scores')) {
        setState(() {
          currentDisplayState = DisplayState.playerScores;
        });
      } else if (data.containsKey('show-players-answers')) {
        setState(() {
          currentDisplayState = DisplayState.playerAnswers;
        });
      } else if (data.containsKey('show-answer')) {
        setState(() {
          currentDisplayState = DisplayState.answer;
        });
      } else if (data.containsKey('start-timer')) {
        setState(() {
          currentDisplayState = DisplayState.timer;
        });
        startTimer(data['start-timer'] * 1000);
      } else if (data.containsKey('pause-timer')) {
        pauseTimer();
      } else if (data.containsKey('reset-timer')) {
        resetTimer();
      } else if (data.containsKey('right-order')) {
        setState(() {
          currentDisplayState = DisplayState.rightOrder;
          currentRightOrder = data['right-order'];
          imageData = List<List<dynamic>>.from(data['data'] ?? [])..shuffle();
          showLabels = false;
        });
      } else if (data.containsKey('show-right-order-answer')) {
        setState(() {
          currentDisplayState = DisplayState.rightOrder;
          currentRightOrder = data['show-right-order-answer'];
          imageData = List<List<dynamic>>.from(data['data'] ?? []);
          showLabels = true;
        });
      }

    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void setCurrentDisplayState(DisplayState state) {
    setState(() {
      currentDisplayState = state;
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    channel.sink.close();
    super.dispose();
  }

  void startTimer(int duration) {
    setState(() {
      remainingTime = duration;
    });

    countdownTimer?.cancel();

    const oneMs = Duration(milliseconds: 10);
    countdownTimer = Timer.periodic(oneMs, (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime -= 10;
        } else {
          countdownTimer?.cancel();
        }
      });
    });
  }

  void pauseTimer() {
    countdownTimer?.cancel();
  }

  void resetTimer() {
    countdownTimer?.cancel();
    setState(() {
      remainingTime = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Room'),
      ),
      body: Center(
        child: buildDisplay(),
      ),
    );
  }

  Widget buildDisplay() {
    switch (currentDisplayState) {
      case DisplayState.question:
        return QuestionDisplay(
          question: currentQuestion,
          imageUrl: imageUrl,
        );
      case DisplayState.timer:
        return TimerDisplay(remainingTime: remainingTime,);
      case DisplayState.rightOrder:
        return RightOrderDisplay(currentRightOrder: currentRightOrder, imageData: imageData, showLabels: showLabels,);
      case DisplayState.playerScores:
        return PlayerScoresDisplay(roomId: widget.roomId);
      case DisplayState.playerAnswers:
        return PlayerAnswersDisplay(roomId: widget.roomId, currentAnswer: currentAnswer);
      case DisplayState.themes:
        return ThemesDisplay(themes: themes);
      case DisplayState.themeAnswers:
        return ThemeAnswersDisplay(themeAnswers: themeAnswers);
      case DisplayState.answer:
        return AnswerDisplay(answer: currentAnswer);
      }
  }
}
