import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getServerIpAddress() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('server_ip');
}

Future<String?> getPlayerId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('player_id');
}

Future<String?> getRoomId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('room_id');
}

Future<void> setPreference(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}