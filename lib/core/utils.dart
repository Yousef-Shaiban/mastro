import 'package:flutter/material.dart';

extension Tools<T extends Object> on T {
  B scope<B>(B Function(T) it) {
    return it(this);
  }
}

extension ToolsNullable<T> on T? {
  bool get isNull {
    return this == null;
  }

  bool get isNotNull {
    return this != null;
  }

  String get str {
    return toString();
  }
}

extension IterableTools<T> on Iterable<T> {
  Iterable<U> mapIndexed<U>(U Function(T e, int i) f) {
    int i = 0;
    return map<U>((it) {
      final t = i;
      i++;
      return f(it, t);
    });
  }

  Iterable<U> mapIndexedWithLength<U>(U Function(T e, int i, int l) f) {
    int i = 0;
    return map<U>((it) {
      final t = i;
      i++;
      return f(it, t, length);
    });
  }

  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T reduceNotEmpty(T Function(T value, T element) combine,
      {required T defaultValue}) {
    if (isEmpty) {
      return defaultValue;
    }
    return reduce(combine);
  }
}

extension ColorFilterTint on Color {
  ColorFilter get cf => ColorFilter.mode(this, BlendMode.srcIn);
}

class Condition<T> {
  final bool ifTrue;
  final T thenReturn;

  Condition({required this.ifTrue, required this.thenReturn});
}

class ConditionBuilder {
  static T when<T>(List<Condition<T>> conditions, {required T orElse}) {
    return conditions.firstWhereOrNull((element) {
          return element.ifTrue;
        })?.thenReturn ??
        orElse;
  }

  static T? whenNullable<T>(List<Condition<T>> conditions, {T? orElse}) {
    return conditions.firstWhereOrNull((element) {
          return element.ifTrue;
        })?.thenReturn ??
        orElse;
  }
}

extension ListTools<T> on List<T> {
  /// Splits list into chunks of specified size
  Iterable<List<T>> chunks(int size) sync* {
    for (var i = 0; i < length; i += size) {
      yield sublist(i, i + size > length ? length : i + size);
    }
  }

  /// Returns a new list with duplicates removed while preserving order
  List<T> distinctBy<K>(K Function(T) keyOf) {
    final seen = <K>{};
    return where((element) => seen.add(keyOf(element))).toList();
  }
}

extension StringTools on String {
  /// Checks if string contains only digits
  bool get isNumeric => RegExp(r'^-?\d*\.?\d+$').hasMatch(this);

  /// Capitalizes first letter of the string
  String get capitalize =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  /// Checks if string is a valid email
  bool get isEmail =>
      RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(this);

  /// Removes all whitespace from string
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Truncates string to specified length with ellipsis
  String truncate(int length, {String suffix = '...'}) =>
      (this.length <= length) ? this : '${substring(0, length)}$suffix';
}

extension NumTools on num {
  /// Clamps the number between min and max values
  num clamp(num min, num max) => this < min ? min : (this > max ? max : this);

  /// Converts number to duration in milliseconds
  Duration get milliseconds => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
  Duration get minutes => Duration(minutes: toInt());
}

extension DateTimeTools on DateTime {
  /// Returns true if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Returns true if date is in the future
  bool get isFuture => isAfter(DateTime.now());
}

class LDBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget loading;
  final Widget Function(T data) data;
  final T Function(T data)? dataRetrieve;

  const LDBuilder(
      {super.key,
      required this.future,
      required this.loading,
      required this.data,
      this.dataRetrieve});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) => snapshot.hasData
          ? data(dataRetrieve != null
              ? dataRetrieve!(snapshot.data as T)
              : snapshot.data as T)
          : loading,
    );
  }
}
