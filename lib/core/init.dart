import 'package:shared_preferences/shared_preferences.dart';

/// Handles initialization of the Mastro framework.
class MastroInit {
  static bool _initialized = false;

  /// Provides persistent storage functionality.
  static late final SharedPreferences persistro;

  /// Initializes the Mastro framework.
  static Future<void> initialize() async {
    if (_initialized) return;

    persistro = await SharedPreferences.getInstance();

    _initialized = true;
  }

  /// Whether the framework has been initialized.
  static bool get isInitialized => _initialized;
}
