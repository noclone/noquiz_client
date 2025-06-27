import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:noquiz_client/utils/preferences.dart';

void checkRoomState(String roomId, Function goToNextPage) async {
  final serverIp = await getServerIpAddress();
  final url = Uri.parse('http://$serverIp:8000/api/rooms/$roomId');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data["started"]) {
      goToNextPage();
    }
  } else {
    print('Failed to load question');
  }
}