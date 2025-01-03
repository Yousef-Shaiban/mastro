/// A container for a mutable value of type T.
final class Mutable<T> {
  /// The contained value.
  T value;

  /// Creates a new mutable container with the given value.
  Mutable(this.value);
}

/// Extension to create a mutable container from any value.
extension MutableCall<T> on T {
  /// Returns this value wrapped in a [Mutable] container.
  Mutable<T> get mutable {
    return Mutable<T>(this);
  }
}
