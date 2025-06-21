import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

void sendToSocket(WebSocketChannel channel, MessageSubject subject, String action, Map<String, dynamic> content)
{
  channel.sink.add(jsonEncode({
    "SUBJECT": subject.name,
    "ACTION": action,
    "CONTENT": jsonEncode(content),
  }));
}

enum MessageSubject {
  NONE,
  PLAYER_INIT,
  PLAYER_NAME,
  GAME_STATE,
  BUZZER,
  PLAYER_ANSWER,
  RIGHT_ORDER,
  TIMER,
  PLAYER_SCORE,
  QUESTION,
  BOARD,
  THEMES,
}

MessageSubject stringToMessageSubject(String value) {
  switch (value) {
    case 'PLAYER_NAME':
      return MessageSubject.PLAYER_NAME;
    case 'GAME_STATE':
      return MessageSubject.GAME_STATE;
    case 'BUZZER':
      return MessageSubject.BUZZER;
    case 'PLAYER_ANSWER':
      return MessageSubject.PLAYER_ANSWER;
    case 'RIGHT_ORDER':
      return MessageSubject.RIGHT_ORDER;
    case 'PLAYER_INIT':
      return MessageSubject.PLAYER_INIT;
    case 'TIMER':
      return MessageSubject.TIMER;
    case 'PLAYER_SCORE':
      return MessageSubject.PLAYER_SCORE;
    case 'QUESTION':
      return MessageSubject.QUESTION;
    case 'BOARD':
      return MessageSubject.BOARD;
    case 'THEMES':
      return MessageSubject.THEMES;
    default:
      return MessageSubject.NONE;
  }
}

class MessageData {
  final MessageSubject subject;
  final String action;
  final Map<String, dynamic> content;
  MessageData(this.subject, this.action, this.content);
}

MessageData decodeMessageData(String message){
  final data = jsonDecode(message);
  MessageSubject subject = stringToMessageSubject(data["SUBJECT"]);
  String action = data["ACTION"];
  Map<String, dynamic> content = data["CONTENT"];
  return MessageData(subject, action, content);
}