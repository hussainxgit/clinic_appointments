// lib/core/data/firebase_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'repository.dart';

abstract class FirebaseRepository<T> implements Repository<T> {
  final FirebaseFirestore firestore;
  final String collection;
  
  FirebaseRepository({
    required this.firestore,
    required this.collection,
  });
  
  Map<String, dynamic> toMap(T entity);
  T fromMap(Map<String, dynamic> map, String id);
  String getId(T entity);
  
  @override
  Future<List<T>> getAll() async {
    final snapshot = await firestore.collection(collection).get();
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }
  
  @override
  Future<T?> getById(String id) async {
    final doc = await firestore.collection(collection).doc(id).get();
    return doc.exists ? fromMap(doc.data()!, doc.id) : null;
  }
  
  @override
  Future<T> create(T entity) async {
    final docRef = firestore.collection(collection).doc();
    await docRef.set(toMap(entity));
    return fromMap({...toMap(entity), 'id': docRef.id}, docRef.id);
  }
  
  @override
  Future<T> update(T entity) async {
    final id = getId(entity);
    await firestore.collection(collection).doc(id).update(toMap(entity));
    return entity;
  }
  
  @override
  Future<bool> delete(String id) async {
    await firestore.collection(collection).doc(id).delete();
    return true;
  }
}