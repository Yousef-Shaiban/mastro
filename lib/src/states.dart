/// Represents the asynchronous state of a computation or data load operation.
///
/// It models four common states:
/// - `initial`: The initial state, optionally holding a cached or default [data].
/// - `loading`: Indicates the operation is in progress.
/// - `data`: Carries the successfully loaded [data].
/// - `error`: Holds an error [message] and optional extra information.
///
/// This sealed class uses Dart's pattern matching `switch` expressions and
/// supports exhaustive (`when`) and non-exhaustive (`maybeWhen`) matching.
sealed class AsyncState<T> {
  /// Private constructor to prevent external subclassing.
  const AsyncState();

  /// Represents the initial state, optionally with cached or default data.
  const factory AsyncState.initial({T? data}) = _Initial<T>;

  /// Represents the loading state.
  const factory AsyncState.loading() = _Loading<T>;

  /// Represents the successful state with loaded [data].
  const factory AsyncState.data(T data) = _Data<T>;

  /// Represents the error state with a message and optional extra metadata.
  ///
  /// [extra] can hold additional information such as error codes or debug data.
  const factory AsyncState.error(
    String message, {
    Map<String, dynamic>? extra,
  }) = _Error<T>;

  /// Returns `true` if the state is [initial].
  bool get isInitial => this is _Initial<T>;

  /// Returns `true` if the state is [loading].
  bool get isLoading => this is _Loading<T>;

  /// Returns `true` if the state is [data].
  bool get isData => this is _Data<T>;

  /// Returns `true` if the state is [error].
  bool get isError => this is _Error<T>;

  /// Returns the current data if state is [data] or [initial] with data, else `null`.
  T? get valueOrNull => switch (this) {
        _Data<T>(data: final d) => d,
        _Initial<T>(data: final d) => d,
        _ => null,
      };

  /// Exhaustive pattern matching on the current state.
  ///
  /// All callbacks are required.
  R when<R>({
    required R Function(T? data) initial,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(String message, Map<String, dynamic>? extra) error,
  }) {
    return switch (this) {
      _Initial<T>(data: final d) => initial(d),
      _Loading<T>() => loading(),
      _Data<T>(data: final d) => data(d),
      _Error<T>(message: final m, extra: final e) => error(m, e),
    };
  }

  /// Partial pattern matching with fallback.
  ///
  /// Callbacks are optional; [orElse] is required.
  R maybeWhen<R>({
    R Function(T? data)? initial,
    R Function()? loading,
    R Function(T data)? data,
    R Function(String message, Map<String, dynamic>? extra)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      _Initial<T>(data: final d) => initial?.call(d) ?? orElse(),
      _Loading<T>() => loading?.call() ?? orElse(),
      _Data<T>(data: final d) => data?.call(d) ?? orElse(),
      _Error<T>(message: final m, extra: final e) => error?.call(m, e) ?? orElse(),
    };
  }
}

/// Initial state of [AsyncState], optionally holding cached [data].
final class _Initial<T> extends AsyncState<T> {
  /// Optional cached or default data.
  final T? data;

  /// Creates an initial state with optional [data].
  const _Initial({this.data});
}

/// Loading state indicating the asynchronous operation is in progress.
final class _Loading<T> extends AsyncState<T> {
  /// Creates a loading state.
  const _Loading();
}

/// Data state representing successfully loaded [data].
final class _Data<T> extends AsyncState<T> {
  /// The loaded data.
  final T data;

  /// Creates a data state with [data].
  const _Data(this.data);
}

/// Error state representing a failure with a [message] and optional [extra] data.
final class _Error<T> extends AsyncState<T> {
  /// Error message describing the failure.
  final String message;

  /// Optional extra metadata, such as error codes or debug info.
  final Map<String, dynamic>? extra;

  /// Creates an error state with a [message] and optional [extra] data.
  const _Error(this.message, {this.extra});
}
