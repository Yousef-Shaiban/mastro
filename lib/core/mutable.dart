final class Mutable<T> {
  T value;

  Mutable(this.value);
}

extension MutableCall<T> on T {
  Mutable<T> get mutable {
    return Mutable<T>(this);
  }
}
