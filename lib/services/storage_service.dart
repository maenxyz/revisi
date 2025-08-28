import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'firebase_service.dart';

class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  Future<String> uploadProfileImage(File file, String username) async {
    final ext = p.extension(file.path).toLowerCase();
    final ref = FirebaseService.instance.storage.ref('${FirebaseService.instance.profilesDir}/$username$ext');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
    // Storage rules harus mengizinkan.
  }

  Future<String> uploadProductImage(File file, String stockId) async {
    final sanitized = stockId.replaceAll('/', '_');
    final ref = FirebaseService.instance.storage.ref('${FirebaseService.instance.productsDir}/$sanitized.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }
}
