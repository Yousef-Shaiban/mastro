import 'package:shared_preferences/shared_preferences.dart';

class MastroInit {
  static bool _initialized = false;
  static late final SharedPreferences persistro;

  static Future<void> initialize() async {
    if (_initialized) return;

    persistro = await SharedPreferences.getInstance();

    _initialized = true;
  }

  static bool get isInitialized => _initialized;
}
