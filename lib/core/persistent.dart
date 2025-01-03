// Base persistence functionality as a mixin
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'init.dart';
import 'state.dart';

/// Provides persistent storage functionality using SharedPreferences.
class Persistro {
  const Persistro._();

  static SharedPreferences get _sharedPreferences {
    if (!MastroInit.isInitialized) {
      try {
        throw StateError('''

╔════════════════════════════════════════════════════════════════════════════╗
║                              PERSISTRO ERROR                               ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Cannot create Persistent value before Mastro initialization!               ║
║                                                                            ║
║ Please initialize Mastro before creating Persistent states:                ║
║                                                                            ║
║ void main() async {                                                        ║
║   WidgetsFlutterBinding.ensureInitialized();                               ║
║   await MastroInit.initialize();                                           ║
║   ...                                                                      ║
║   runApp(MaterialApp(                                                      ║
║     home: YourHomeWidget(),                                                ║
║   ));                                                                      ║
║ }                                                                          ║
╚════════════════════════════════════════════════════════════════════════════╝
      ''');
      } catch (e) {
        debugPrint(e.toString(), wrapWidth: 1024); // Adjust wrapWidth as needed
      }
    }
    return MastroInit.persistro;
  }

  /// Stores a string value.
  static Future<void> putString(String key, String value) async {
    await _sharedPreferences.setString(key, value);
  }

  /// Stores an integer value.
  static Future<void> putInt(String key, int value) async {
    await _sharedPreferences.setInt(key, value);
  }

  /// Stores a double value.
  static Future<void> putDouble(String key, double value) async {
    await _sharedPreferences.setDouble(key, value);
  }

  /// Stores a boolean value.
  static Future<void> putBool(String key, bool value) async {
    await _sharedPreferences.setBool(key, value);
  }

  /// Stores a list of strings.
  static Future<void> putStringList(String key, List<String> value) async {
    await _sharedPreferences.setStringList(key, value);
  }

  /// Retrieves a stored string value.
  static Future<String?> getString(String key) async {
    return _sharedPreferences.getString(key);
  }

  /// Retrieves a stored integer value.
  static Future<int?> getInt(String key) async {
    return _sharedPreferences.getInt(key);
  }

  /// Retrieves a stored double value.
  static Future<double?> getDouble(String key) async {
    return _sharedPreferences.getDouble(key);
  }

  /// Retrieves a stored boolean value.
  static Future<bool?> getBool(String key) async {
    return _sharedPreferences.getBool(key);
  }

  /// Retrieves a stored list of strings.
  static Future<List<String>?> getStringList(String key) async {
    return _sharedPreferences.getStringList(key);
  }
}

/// Mixin that adds persistence capabilities to state objects.
mixin PersistroMixin<T> on Basetro<T> {
  /// Unique key for storing this state.
  String get key;

  /// Function to decode stored string into value of type T.
  T Function(String) get decoder;

  /// Function to encode value of type T into string.
  String Function(T) get encoder;

  /// Whether to automatically save on changes.
  bool get autoSave;

  bool _isRestoring = false;
  String? _lastSavedValue;

  SharedPreferences get _sharedPreferences => MastroInit.persistro;

  /// Initializes the persistence system.
  void initPersistence() {
    if (!MastroInit.isInitialized) {
      try {
        throw StateError('''

╔════════════════════════════════════════════════════════════════════════════╗
║                              PERSISTRO ERROR                               ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Cannot create Persistent state before Mastro initialization!               ║
║                                                                            ║
║ Please initialize Mastro before creating Persistent states:                ║
║                                                                            ║
║ void main() async {                                                        ║
║   WidgetsFlutterBinding.ensureInitialized();                               ║
║   await MastroInit.initialize();                                           ║
║   ...                                                                      ║
║   runApp(MaterialApp(                                                      ║
║     home: YourHomeWidget(),                                                ║
║   ));                                                                      ║
║ }                                                                          ║
╚════════════════════════════════════════════════════════════════════════════╝
      ''');
      } catch (e) {
        debugPrint(e.toString(), wrapWidth: 1024);
        return; // Adjust wrapWidth as needed
      }
    }

    if (autoSave) {
      addListener(_handleAutoSave);
    }
    restore();
  }

  void _handleAutoSave() {
    if (_isRestoring) return;
    final currentEncoded = encoder(value);
    if (_lastSavedValue != currentEncoded) {
      persist();
    }
  }

  /// Persists the current value.
  Future<void> persist() async {
    try {
      final data = encoder(value);
      await _sharedPreferences.setString(key, data);
      _lastSavedValue = data;
      debugPrint('PERSISTRO: Persisted $key: $data');
    } catch (e) {
      debugPrint('PERSISTRO: Error persisting $key: $e');
    }
  }

  /// Restores the persisted value.
  Future<void> restore() async {
    try {
      final data = _sharedPreferences.getString(key);
      if (data != null) {
        _isRestoring = true;
        value = decoder(data);
        _lastSavedValue = data;
        _isRestoring = false;
        debugPrint('PERSISTRO: Restored $key: $data');
      }
    } catch (e) {
      debugPrint('PERSISTRO: Error restoring $key: $e');
    }
  }

  /// Clears the persisted value.
  Future<void> clear() async {
    try {
      await _sharedPreferences.remove(key);
      value = super.value;
      _lastSavedValue = null;
      debugPrint('Persistro: Cleared $key');
    } catch (e) {
      debugPrint('Persistro: Error clearing $key: $e');
    }
  }

  /// Cleans up persistence resources.
  void disposePersistence() {
    if (autoSave) {
      removeListener(_handleAutoSave);
    }
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }
}

/// Persistent version of Mastro state container.
class PersistroMastro<T> extends Mastro<T> with PersistroMixin<T> {
  @override
  final String key;
  @override
  final T Function(String) decoder;
  @override
  final String Function(T) encoder;
  @override
  final bool autoSave;

  /// Creates a persistent Mastro state container.
  PersistroMastro({
    required T initial,
    required this.key,
    required this.decoder,
    required this.encoder,
    this.autoSave = true,
  }) : super.of(initial) {
    initPersistence();
  }

  /// Creates a persistent numeric state container.
  static PersistroMastro<num> number(
    String key, {
    num initial = 0.0,
    bool autoSave = true,
  }) {
    return PersistroMastro<num>(
      key: key,
      initial: initial,
      decoder: (json) => num.parse(json),
      encoder: (value) => value.toString(),
      autoSave: autoSave,
    );
  }

  /// Creates a persistent string state container.
  static PersistroMastro<String> string(
    String key, {
    String initial = '',
    bool autoSave = true,
  }) {
    return PersistroMastro<String>(
      key: key,
      initial: initial,
      decoder: (json) => json,
      encoder: (value) => value,
      autoSave: autoSave,
    );
  }

  /// Creates a persistent boolean state container.
  static PersistroMastro<bool> boolean(
    String key, {
    bool initial = false,
    bool autoSave = true,
  }) {
    return PersistroMastro<bool>(
      key: key,
      initial: initial,
      decoder: (json) => json.toLowerCase() == 'true',
      encoder: (value) => value.toString(),
      autoSave: autoSave,
    );
  }

  /// Creates a persistent list state container.
  static PersistroMastro<List<T>> list<T>(
    String key, {
    required List<T> initial,
    required T Function(dynamic) fromJson,
    bool autoSave = true,
  }) {
    return PersistroMastro<List<T>>(
      key: key,
      initial: initial,
      decoder: (json) => List<T>.from(
        jsonDecode(json).map((x) => fromJson(x)),
      ),
      encoder: (value) => jsonEncode(value),
      autoSave: autoSave,
    );
  }

  /// Creates a persistent map state container.
  static PersistroMastro<Map<String, T>> map<T>(
    String key, {
    required Map<String, T> initial,
    required T Function(dynamic) fromJson,
    bool autoSave = true,
  }) {
    return PersistroMastro<Map<String, T>>(
      key: key,
      initial: initial,
      decoder: (json) => Map<String, T>.from(
        jsonDecode(json).map((k, v) => MapEntry(k, fromJson(v))),
      ),
      encoder: (value) => jsonEncode(value),
      autoSave: autoSave,
    );
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }
}

/// Persistent version of Lightro state container.
class PersistroLightro<T> extends Lightro<T> with PersistroMixin<T> {
  @override
  final String key;
  @override
  final T Function(String) decoder;
  @override
  final String Function(T) encoder;
  @override
  final bool autoSave;

  /// Creates a persistent Lightro state container.
  PersistroLightro({
    required T initial,
    required this.key,
    required this.decoder,
    required this.encoder,
    this.autoSave = true,
  }) : super.of(initial) {
    initPersistence();
  }

  /// Creates a persistent numeric state container.
  static PersistroLightro<num> number(
    String key, {
    num initial = 0.0,
    bool autoSave = true,
  }) {
    return PersistroLightro<num>(
      key: key,
      initial: initial,
      decoder: (json) => num.parse(json),
      encoder: (value) => value.toString(),
      autoSave: autoSave,
    );
  }

  /// Creates a persistent string state container.
  static PersistroLightro<String> string(
    String key, {
    String initial = '',
    bool autoSave = true,
  }) {
    return PersistroLightro<String>(
      key: key,
      initial: initial,
      decoder: (json) => json,
      encoder: (value) => value,
      autoSave: autoSave,
    );
  }

  /// Creates a persistent boolean state container.
  static PersistroLightro<bool> boolean(
    String key, {
    bool initial = false,
    bool autoSave = true,
  }) {
    return PersistroLightro<bool>(
      key: key,
      initial: initial,
      decoder: (json) => json.toLowerCase() == 'true',
      encoder: (value) => value.toString(),
      autoSave: autoSave,
    );
  }

  /// Creates a persistent list state container.
  static PersistroLightro<List<T>> list<T>(
    String key, {
    required List<T> initial,
    required T Function(dynamic) fromJson,
    bool autoSave = true,
  }) {
    return PersistroLightro<List<T>>(
      key: key,
      initial: initial,
      decoder: (json) => List<T>.from(
        jsonDecode(json).map((x) => fromJson(x)),
      ),
      encoder: (value) => jsonEncode(value),
      autoSave: autoSave,
    );
  }

  /// Creates a persistent map state container.
  static PersistroLightro<Map<String, T>> map<T>(
    String key, {
    required Map<String, T> initial,
    required T Function(dynamic) fromJson,
    bool autoSave = true,
  }) {
    return PersistroLightro<Map<String, T>>(
      key: key,
      initial: initial,
      decoder: (json) => Map<String, T>.from(
        jsonDecode(json).map((k, v) => MapEntry(k, fromJson(v))),
      ),
      encoder: (value) => jsonEncode(value),
      autoSave: autoSave,
    );
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }
}
