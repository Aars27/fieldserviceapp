import 'failures.dart';

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}

extension ResultX<T> on Result<T> {
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T get unwrap => (this as Ok<T>).value;
  Failure get unwrapErr => (this as Err<T>).failure;

  R fold<R>(R Function(Failure) onErr, R Function(T) onOk) {
    return switch (this) {
      Ok(:final value) => onOk(value),
      Err(:final failure) => onErr(failure),
    };
  }
}
