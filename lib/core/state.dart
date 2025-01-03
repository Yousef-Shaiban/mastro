import 'dart:developer';

import 'package:flutter/material.dart';

import 'mutable.dart';

extension StateTools<T> on T {
  Lightro<T> get lightro {
    return Lightro<T>.of(this);
  }

  Mastro<T> get mastro {
    return Mastro<T>.of(this);
  }
}

extension MastroBoolTools on Basetro<bool> {
  void toggle() {
    value = !value;
  }
}

abstract class Basetro<T> with ChangeNotifier {
  late final Mutable<T> _data;

  set value(T value) {
    if (_data.value != value) {
      _data.value = value;
      notify();
    }
  }

  set nonNotifiableSetter(T value) {
    _data.value = value;
  }

  T get value => _data.value;

  void modify(void Function(Mutable<T> mastro) modify) {
    modify(_data);
    notify();
  }

  void notify() => notifyListeners();

  Basetro(T data) {
    _data = Mutable(data);
  }
}

class Lightro<T> extends Basetro<T> {
  Lightro.of(super.data);
}

class Mastro<T> extends Basetro<T> {
  final Map<Basetro, VoidCallback> _computedStates = {};
  final Map<Basetro, VoidCallback> _dependencies = {};
  final Map<String, void Function(T value)> _observers = {};
  bool Function(T value)? _validator;

  Mastro<R> compute<R>(R Function(T value) calculator) {
    final computed = calculator(value).mastro;
    void listener() => computed.value = calculator(value);
    addListener(listener);
    _computedStates[computed] = listener;
    return computed;
  }

  void dependsOn(Basetro other) {
    void listener() => notify();
    other.addListener(listener);
    _dependencies[other] = listener;
  }

  void removeDependency(Mastro other) {
    final listener = _dependencies[other];
    if (listener != null) {
      other.removeListener(listener);
      _dependencies.remove(other);
    }
  }

  void observe(String key, void Function(T value) callback) {
    _observers[key] = callback;
  }

  void removeObserver(String key) {
    _observers.remove(key);
  }

  void notifyObservers() {
    for (final observer in _observers.values) {
      observer(value);
    }
  }

  @override
  void dispose() {
    for (final entry in _dependencies.entries) {
      entry.key.removeListener(entry.value);
    }
    _dependencies.clear();

    for (final entry in _computedStates.entries) {
      removeListener(entry.value);
    }
    _computedStates.clear();
    _observers.clear();
    super.dispose();
  }

  Mastro.of(super.data);

  @override
  void notify() {
    super.notify();
    notifyObservers();
  }

  void setValidator(bool Function(T value) validator) {
    _validator = validator;
  }

  @override
  set nonNotifiableSetter(T value) {
    if (_validator?.call(value) ?? true) {
      super.nonNotifiableSetter = value;
    } else {
      log('Mastro<${T.runtimeType}> validator failed for value: $value');
    }
  }

  @override
  set value(T newValue) {
    if (_validator?.call(newValue) ?? true) {
      super.value = newValue;
    } else {
      log('Mastro<${T.runtimeType}> validator failed for value: $newValue');
    }
  }
}

mixin UniqueBasetroMixin<T> on Basetro<T> {
  String get tag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniqueBasetroMixin &&
          runtimeType == other.runtimeType &&
          tag == other.tag;

  @override
  int get hashCode => tag.hashCode;
}

extension BasetroDebug<T> on Basetro<T> {
  void debugLog([String? name]) {
    addListener(() {
      log('Tro${name != null ? "($name)" : ""}<$T> updated: $value');
    });
  }
}
