// lib/core/utils/result.dart
class Result<T> {
  final T? _data;
  final String? _error;
  final bool _isSuccess;

  const Result._({
    T? data,
    String? error,
    required bool isSuccess,
  })  : _data = data,
        _error = error,
        _isSuccess = isSuccess;

  factory Result.success(T data) => Result._(
        data: data,
        isSuccess: true,
      );

  factory Result.failure(String error) => Result._(
        error: error,
        isSuccess: false,
      );

  bool get isSuccess => _isSuccess;
  bool get isFailure => !_isSuccess;

  T get data {
    if (isFailure) throw Exception("Cannot get data from failure result");
    return _data as T;
  }

  String get error {
    if (isSuccess) throw Exception("Cannot get error from success result");
    return _error!;
  }
  
  // Add some useful methods
  void when({
    required Function(T data) success,
    required Function(String error) failure,
  }) {
    if (isSuccess) {
      success(data);
    } else {
      failure(error);
    }
  }
  
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      return Result.success(transform(data));
    } else {
      return Result.failure(error);
    }
  }
  
  // Useful for chaining operations
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    if (isSuccess) {
      return transform(data);
    } else {
      return Result.failure(error);
    }
  }
}