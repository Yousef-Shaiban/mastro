import 'package:shared_preferences/shared_preferences.dart';

/// Handles initialization of the Mastro framework.
///
/// This class ensures that the framework is set up properly before use, including persistent
/// storage via [SharedPreferences].
class MastroInit {
  /// Tracks whether the framework has been initialized.
  static bool _initialized = false;

  /// Provides persistent storage functionality after initialization.
  static late final SharedPreferences persistro;

  /// Initializes the Mastro framework.
  ///
  /// Sets up [persistro] with an instance of [SharedPreferences]. Does nothing if already
  /// initialized. Returns a [Future] that completes when initialization is done.
  static Future<void> initialize() async {
    if (_initialized) return;

    persistro = await SharedPreferences.getInstance();

    _initialized = true;
  }

  /// Checks if the framework has been initialized.
  ///
  /// Returns `true` if [initialize] has been called successfully, `false` otherwise.
  static bool get isInitialized => _initialized;
}
