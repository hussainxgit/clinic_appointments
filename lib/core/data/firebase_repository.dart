// lib/core/data/firebase_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/error_handler.dart';
import '../utils/result.dart';
import 'repository.dart';

abstract class FirebaseRepository<T> implements Repository<T> {
  final FirebaseFirestore firestore;
  final String collection;

  FirebaseRepository({required this.firestore, required this.collection});

  // Abstract methods to be implemented by subclasses
  Map<String, dynamic> toMap(T entity);
  T fromMap(Map<String, dynamic> map, String id);
  String getId(T entity);

  @override
  Future<Result<List<T>>> getAll() async {
    return ErrorHandler.guardAsync(() async {
      final snapshot = await firestore.collection(collection).get();
      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching all $collection');
  }

  @override
  Future<Result<T?>> getById(String id) async {
    return ErrorHandler.guardAsync(() async {
      final doc = await firestore.collection(collection).doc(id).get();
      return doc.exists ? fromMap(doc.data()!, doc.id) : null;
    }, 'fetching $collection by ID');
  }

  @override
  Future<Result<T>> create(T entity) async {
    return ErrorHandler.guardAsync(() async {
      final docRef = firestore.collection(collection).doc();
      await docRef.set(toMap(entity));
      return fromMap({...toMap(entity), 'id': docRef.id}, docRef.id);
    }, 'creating $collection');
  }

  @override
  Future<Result<T>> update(T entity) async {
    return ErrorHandler.guardAsync(() async {
      final id = getId(entity);
      await firestore.collection(collection).doc(id).update(toMap(entity));
      return entity;
    }, 'updating $collection');
  }

  @override
  Future<Result<bool>> delete(String id) async {
    return ErrorHandler.guardAsync(() async {
      await firestore.collection(collection).doc(id).delete();
      return true;
    }, 'deleting $collection');
  }
}
