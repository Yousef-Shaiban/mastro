/// A container for a mutable value of type [T].
///
/// This class wraps a value that can be modified directly, used internally by state management
/// classes like [Basetro].
final class Mutable<T> {
  /// The contained value.
  T value;

  /// Creates a new mutable container with the given [value].
  Mutable(this.value);
}

/// Provides an extension to create a [Mutable] container from any value.
///
/// This extension simplifies wrapping a value in a [Mutable] instance.
extension MutableCall<T> on T {
  /// Wraps this value in a [Mutable] container.
  ///
  /// Returns a new [Mutable<T>] instance containing this value.
  Mutable<T> get mutable {
    return Mutable<T>(this);
  }
}
