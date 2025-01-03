// Base persistence functionality as a mixin
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'init.dart';
import 'state.dart';

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

  static Future<void> putString(String key, String value) async {
    await _sharedPreferences.setString(key, value);
  }

  static Future<void> putInt(String key, int value) async {
    await _sharedPreferences.setInt(key, value);
  }

  static Future<void> putDouble(String key, double value) async {
    await _sharedPreferences.setDouble(key, value);
  }

  static Future<void> putBool(String key, bool value) async {
    await _sharedPreferences.setBool(key, value);
  }

  static Future<void> putStringList(String key, List<String> value) async {
    await _sharedPreferences.setStringList(key, value);
  }

  static Future<String?> getString(String key) async {
    return _sharedPreferences.getString(key);
  }

  static Future<int?> getInt(String key) async {
    return _sharedPreferences.getInt(key);
  }

  static Future<double?> getDouble(String key) async {
    return _sharedPreferences.getDouble(key);
  }

  static Future<bool?> getBool(String key) async {
    return _sharedPreferences.getBool(key);
  }

  static Future<List<String>?> getStringList(String key) async {
    return _sharedPreferences.getStringList(key);
  }
}

mixin PersistroMixin<T> on Basetro<T> {
  String get key;
  T Function(String) get decoder;
  String Function(T) get encoder;
  bool get autoSave;

  bool _isRestoring = false;
  String? _lastSavedValue;

  SharedPreferences get _sharedPreferences => MastroInit.persistro;

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

// Persistent Mastro implementation
class PersistroMastro<T> extends Mastro<T> with PersistroMixin<T> {
  @override
  final String key;
  @override
  final T Function(String) decoder;
  @override
  final String Function(T) encoder;
  @override
  final bool autoSave;

  PersistroMastro({
    required T initial,
    required this.key,
    required this.decoder,
    required this.encoder,
    this.autoSave = true,
  }) : super.of(initial) {
    initPersistence();
  }

  // Factory constructors for MastroPersistro
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

// Persistent Lightro implementation
class PersistroLightro<T> extends Lightro<T> with PersistroMixin<T> {
  @override
  final String key;
  @override
  final T Function(String) decoder;
  @override
  final String Function(T) encoder;
  @override
  final bool autoSave;

  PersistroLightro({
    required T initial,
    required this.key,
    required this.decoder,
    required this.encoder,
    this.autoSave = true,
  }) : super.of(initial) {
    initPersistence();
  }

  // Factory constructors for LightroPersistro
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
