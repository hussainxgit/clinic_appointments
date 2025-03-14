// lib/core/data/repository.dart
abstract class Repository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<T> create(T entity);
  Future<T> update(T entity);
  Future<bool> delete(String id);
}