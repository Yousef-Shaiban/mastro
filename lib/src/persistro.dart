import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mastro/src/internal/extra.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core.dart';

/// Provides persistent storage functionality using [SharedPreferences].
///
/// This class offers static methods to store and retrieve values persistently, requiring
/// [Persistro.initialize] to be called first.
class Persistro {
  static bool _initialized = false;

  /// Provides persistent storage functionality after initialization.
  static late final SharedPreferences store;

  /// Initializes the Persistro framework.
  ///
  /// Sets up [store] with an instance of [SharedPreferences]. Does nothing if already
  /// initialized. Returns a [Future] that completes when initialization is done.
  static Future<void> initialize() async {
    if (_initialized) return;

    store = await SharedPreferences.getInstance();

    _initialized = true;
  }

  /// Returns `true` if [initialize] has been called successfully, `false` otherwise.
  static bool get isInitialized => _initialized;

  /// Private constructor to prevent instantiation.
  const Persistro._();

  /// Internal access to [SharedPreferences] instance.
  static SharedPreferences get _sharedPreferences {
    if (!isInitialized) {
      throw StateError('Persistro must be initialized before using it. '
          'Call await Persistro.initialize() in main().');
    }
    return store;
  }

  /// Stores a string value persistently.
  ///
  /// [key] is the unique identifier for the value. [value] is the string to store.
  static Future<void> putString(String key, String value) async {
    await _sharedPreferences.setString(key, value);
  }

  /// Stores an integer value persistently.
  ///
  /// [key] is the unique identifier for the value. [value] is the integer to store.
  static Future<void> putInt(String key, int value) async {
    await _sharedPreferences.setInt(key, value);
  }

  /// Stores a double value persistently.
  ///
  /// [key] is the unique identifier for the value. [value] is the double to store.
  static Future<void> putDouble(String key, double value) async {
    await _sharedPreferences.setDouble(key, value);
  }

  /// Stores a boolean value persistently.
  ///
  /// [key] is the unique identifier for the value. [value] is the boolean to store.
  static Future<void> putBool(String key, bool value) async {
    await _sharedPreferences.setBool(key, value);
  }

  /// Stores a list of strings persistently.
  ///
  /// [key] is the unique identifier for the value. [value] is the list of strings to store.
  static Future<void> putStringList(String key, List<String> value) async {
    await _sharedPreferences.setStringList(key, value);
  }

  /// Retrieves a stored string value.
  ///
  /// [key] is the identifier of the value to retrieve. Returns the stored string or null if not found.
  static Future<String?> getString(String key) async {
    return _sharedPreferences.getString(key);
  }

  /// Retrieves a stored integer value.
  ///
  /// [key] is the identifier of the value to retrieve. Returns the stored integer or null if not found.
  static Future<int?> getInt(String key) async {
    return _sharedPreferences.getInt(key);
  }

  /// Retrieves a stored double value.
  ///
  /// [key] is the identifier of the value to retrieve. Returns the stored double or null if not found.
  static Future<double?> getDouble(String key) async {
    return _sharedPreferences.getDouble(key);
  }

  /// Retrieves a stored boolean value.
  ///
  /// [key] is the identifier of the value to retrieve. Returns the stored boolean or null if not found.
  static Future<bool?> getBool(String key) async {
    return _sharedPreferences.getBool(key);
  }

  /// Retrieves a stored list of strings.
  ///
  /// [key] is the identifier of the value to retrieve. Returns the stored list or null if not found.
  static Future<List<String>?> getStringList(String key) async {
    return _sharedPreferences.getStringList(key);
  }
}

/// Mixin that adds persistence capabilities to state objects.
///
/// This mixin extends [Basetro] with methods to save and restore state using [SharedPreferences].
///
/// Type parameter [T] represents the type of the value being managed.
mixin _PersistroMixin<T> on Basetro<T> {
  /// The unique key for storing this state in persistent storage.
  String get key;

  /// Function to decode a stored string into a value of type [T].
  T Function(String) get decoder;

  /// Function to encode a value of type [T] into a string for storage.
  String Function(T) get encoder;

  /// Whether to automatically save changes to persistent storage.
  bool get autoSave;

  /// Flag to prevent recursive saves during restoration.
  bool _isRestoring = false;

  /// The last encoded value saved, used to detect changes.
  String? _lastSavedValue;

  /// Internal access to [SharedPreferences] instance.
  SharedPreferences get _sharedPreferences => Persistro.store;

  /// Initializes the persistence system for this state.
  ///
  /// Sets up auto-save listeners if [autoSave] is true and restores any previously saved value.
  /// Throws a [StateError] if [Persistro] is not initialized.
  void initPersistence() {
    if (!isInitialized) {
      try {
        throw StateError('''
╔════════════════════════════════════════════════════════════════════════════╗
║                              PERSISTRO ERROR                               ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Cannot create Persistent state before Persistro initialization!            ║
║                                                                            ║
║ Please initialize Persistro before creating Persistent states:             ║
║                                                                            ║
║ void main() async {                                                        ║
║   WidgetsFlutterBinding.ensureInitialized();                               ║
║   await Persistro.initialize();  // add this line                          ║
║   ...                                                                      ║
║   runApp(MaterialApp(                                                      ║
║     home: YourHomeWidget(),                                                ║
║   ));                                                                      ║
║ }                                                                          ║
╚════════════════════════════════════════════════════════════════════════════╝
      ''');
      } catch (e) {
        debugPrint(e.toString(), wrapWidth: 1024);
        return;
      }
    }

    if (autoSave) {
      addListener(_handleAutoSave);
    }
    restore();
  }

  /// Handles automatic saving when the state changes.
  void _handleAutoSave() {
    if (_isRestoring) return;
    final currentEncoded = encoder(value);
    if (_lastSavedValue != currentEncoded) {
      persist();
    }
  }

  /// Persists the current value to storage.
  ///
  /// Encodes the current [value] and saves it under [key]. Logs success or failure.
  Future<void> persist() async {
    try {
      final data = encoder(value);
      await _sharedPreferences.setString(key, data);
      _lastSavedValue = data;
      mastroLog('State($_typeName) persisted $key: $data');
    } catch (e) {
      mastroLog('State($_typeName) error persisting $key: $e');
    }
  }

  /// Restores the persisted value from storage.
  ///
  /// Retrieves and decodes the value associated with [key], updating the state if found.
  /// Logs success or failure.
  Future<void> restore() async {
    try {
      final data = _sharedPreferences.getString(key);
      if (data != null) {
        _isRestoring = true;
        value = decoder(data);
        _lastSavedValue = data;
        _isRestoring = false;
        mastroLog('State($_typeName) restored $key: $data');
      }
    } catch (e) {
      mastroLog('State($_typeName) error restoring $key: $e');
    }
  }

  /// Clears the persisted value from storage.
  ///
  /// Removes the value associated with [key] and resets the state. Logs success or failure.
  Future<void> clear() async {
    try {
      await _sharedPreferences.remove(key);
      value = super.value;
      _lastSavedValue = null;
      mastroLog('State($_typeName) cleared $key');
    } catch (e) {
      mastroLog('State($_typeName) error clearing $key: $e');
    }
  }

  /// Cleans up persistence resources.
  ///
  /// Removes the auto-save listener if [autoSave] is true.
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

  String get _typeName => runtimeType.toString().replaceAll('<$T>', '');
}

/// A persistent version of the [Mastro] state container.
///
/// Extends [Mastro] with persistence capabilities via [_PersistroMixin], allowing values to
/// be saved and restored using [SharedPreferences].
///
/// Type parameter [T] represents the type of the value being managed.
class PersistroMastro<T> extends Mastro<T> with _PersistroMixin<T> {
  @override
  final String key;

  @override
  final T Function(String) decoder;

  @override
  final String Function(T) encoder;

  @override
  final bool autoSave;

  /// Creates a persistent [Mastro] state container.
  ///
  /// [initial] is the initial value. [key] is the unique storage identifier. [decoder] and
  /// [encoder] convert the value to/from strings. [autoSave] determines if changes are saved automatically.
  PersistroMastro({
    required T initial,
    required this.key,
    required this.decoder,
    required this.encoder,
    this.autoSave = true,
  }) : super.of(initial) {
    initPersistence();
  }

  /// Creates a persistent JSON-serializable state container.
  ///
  /// [key] is the storage identifier. [initial] is the default value. [fromJson] and [toJson]
  /// convert the value to/from JSON. [autoSave] enables automatic saving (defaults to true).
  static PersistroMastro<T> json<T>(
    String key, {
    required T initial,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    bool autoSave = true,
  }) {
    return PersistroMastro<T>(
      key: key,
      initial: initial,
      decoder: (json) => fromJson(jsonDecode(json)),
      encoder: (value) => jsonEncode(toJson(value)),
      autoSave: autoSave,
    );
  }

  /// Creates a persistent numeric state container.
  ///
  /// [key] is the storage identifier. [initial] is the default value (defaults to 0.0).
  /// [autoSave] enables automatic saving (defaults to true).
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
  ///
  /// [key] is the storage identifier. [initial] is the default value (defaults to empty string).
  /// [autoSave] enables automatic saving (defaults to true).
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
  ///
  /// [key] is the storage identifier. [initial] is the default value (defaults to false).
  /// [autoSave] enables automatic saving (defaults to true).
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
  ///
  /// [key] is the storage identifier. [initial] is the default list. [fromJson] decodes
  /// list elements. [autoSave] enables automatic saving (defaults to true).
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
  ///
  /// [key] is the storage identifier. [initial] is the default map. [fromJson] decodes
  /// map values. [autoSave] enables automatic saving (defaults to true).
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

/// A persistent version of the [Lightro] state container.
///
/// Extends [Lightro] with persistence capabilities via [_PersistroMixin], allowing values to
/// be saved and restored using [SharedPreferences].
///
/// Type parameter [T] represents the type of the value being managed.
class PersistroLightro<T> extends Lightro<T> with _PersistroMixin<T> {
  @override
  final String key;

  @override
  final T Function(String) decoder;

  @override
  final String Function(T) encoder;

  @override
  final bool autoSave;

  /// Creates a persistent [Lightro] state container.
  ///
  /// [initial] is the initial value. [key] is the unique storage identifier. [decoder] and
  /// [encoder] convert the value to/from strings. [autoSave] determines if changes are saved automatically.
  PersistroLightro({
    required T initial,
    required this.key,
    required this.decoder,
    required this.encoder,
    this.autoSave = true,
  }) : super.of(initial) {
    initPersistence();
  }

  /// Creates a persistent JSON-serializable state container.
  ///
  /// [key] is the storage identifier. [initial] is the default value. [fromJson] and [toJson]
  /// convert the value to/from JSON. [autoSave] enables automatic saving (defaults to true).
  static PersistroLightro<T> json<T>(
    String key, {
    required T initial,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    bool autoSave = true,
  }) {
    return PersistroLightro<T>(
      key: key,
      initial: initial,
      decoder: (json) => fromJson(jsonDecode(json)),
      encoder: (value) => jsonEncode(toJson(value)),
      autoSave: autoSave,
    );
  }

  /// Creates a persistent numeric state container.
  ///
  /// [key] is the storage identifier. [initial] is the default value (defaults to 0.0).
  /// [autoSave] enables automatic saving (defaults to true).
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
  ///
  /// [key] is the storage identifier. [initial] is the default value (defaults to empty string).
  /// [autoSave] enables automatic saving (defaults to true).
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
  ///
  /// [key] is the storage identifier. [initial] is the default value (defaults to false).
  /// [autoSave] enables automatic saving (defaults to true).
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
  ///
  /// [key] is the storage identifier. [initial] is the default list. [fromJson] decodes
  /// list elements. [autoSave] enables automatic saving (defaults to true).
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
  ///
  /// [key] is the storage identifier. [initial] is the default map. [fromJson] decodes
  /// map values. [autoSave] enables automatic saving (defaults to true).
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
