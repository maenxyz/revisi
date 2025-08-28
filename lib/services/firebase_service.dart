import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  FirebaseFirestore get db => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  // Collections (fixed names)
  String get usersCol => 'uji_ke_seribut';
  String get productsCol => 'uji_ke_seribut_barang';

  // Storage roots
  String get storageRoot => 'upload_test';
  String get profilesDir => '$storageRoot/profiles';
  String get productsDir => '$storageRoot/products';
}
