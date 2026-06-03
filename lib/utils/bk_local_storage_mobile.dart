import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _prefs;

Future<void> bkLocalStorageInit() async {
  _prefs = await SharedPreferences.getInstance();
}

String? bkLocalStorageGet(String key) => _prefs.getString(key);

void bkLocalStorageSet(String key, String value) {
  _prefs.setString(key, value);
}
