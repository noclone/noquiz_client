import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getServerIpAddress() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('server_ip');
}
