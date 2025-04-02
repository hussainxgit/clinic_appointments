// lib/core/data/repository.dart
import '../utils/result.dart';

abstract class Repository<T> {
  // All methods use Result pattern
  Future<Result<List<T>>> getAll();
  Future<Result<T?>> getById(String id);
  Future<Result<T>> create(T entity);
  Future<Result<T>> update(T entity);
  Future<Result<bool>> delete(String id);
}
