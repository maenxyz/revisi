import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
import 'firebase_service.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  // ===== LOGIN =====
  // - Query 1 kolom (username) => aman dari composite index
  // - Verifikasi: passwordHash (bcrypt). Jika masih pakai 'password' (legacy),
  //   cocokkan dulu, lalu MIGRASI: tulis passwordHash & hapus 'password'
  Future<UserModel?> login(String username, String password) async {
    final db = FirebaseService.instance.db;

    final q = await db
        .collection(FirebaseService.instance.usersCol)
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;

    final d = q.docs.first;
    final ref = db.collection(FirebaseService.instance.usersCol).doc(d.id);
    final data = d.data();

    final String? hash = data['passwordHash'] as String?;
    if (hash != null && hash.isNotEmpty) {
      if (!BCrypt.checkpw(password, hash)) return null;
    } else {
      // legacy plaintext
      final legacy = (data['password'] ?? '') as String;
      if (legacy != password) return null;

      // Migrasi → simpan hash & hapus plaintext
      final salt = BCrypt.gensalt();
      final newHash = BCrypt.hashpw(password, salt);
      await ref.update({
        'passwordHash': newHash,
        'password': FieldValue.delete(),
        'updatedAt': DateTime.now(),
      });
    }

    // after-login: baca ulang, cache session
    final fresh = await ref.get();
    final user = UserModel.fromMap(fresh.id, fresh.data()!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('role', user.role);
    await prefs.setString('imageUrl', user.imageUrl ?? '');

    return user;
  }

  // ===== REGISTER =====
  // - Simpan HANYA 'passwordHash' (bcrypt)
  // - Tambah "sapu-bersih" setelah write: hapus field 'password' kalau ada (defense in depth)
  Future<String?> register({
    required String username,
    required String password,
    String role = 'user',
    File? imageFile,
  }) async {
    final db = FirebaseService.instance.db;

    // unik username
    final exist = await db
        .collection(FirebaseService.instance.usersCol)
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (exist.docs.isNotEmpty) {
      return 'Username sudah dipakai';
    }

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await StorageService.instance.uploadProfileImage(imageFile, username);
    }

    final salt = BCrypt.gensalt();
    final hash = BCrypt.hashpw(password, salt);
    final now = DateTime.now();

    // Tulis dokumen TANPA 'password'
    final ref = await db.collection(FirebaseService.instance.usersCol).add({
      'username': username,
      'passwordHash': hash,
      'role': role,
      'imageUrl': imageUrl,
      'createdAt': now,
      'updatedAt': now,
    });

    // Sapu-bersih: kalau ada field 'password' (misal dari code path lama/trigger), hapus paksa.
    await ref.update({'password': FieldValue.delete()});

    return null; // sukses
  }

  Future<UserModel?> currentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      if (uid == null) return null;

      final db = FirebaseService.instance.db;
      final doc = await db.collection(FirebaseService.instance.usersCol).doc(uid).get();
      if (!doc.exists) {
        await logout();
        return null;
      }
      final user = UserModel.fromMap(doc.id, doc.data()!);
      await prefs.setString('username', user.username);
      await prefs.setString('role', user.role);
      await prefs.setString('imageUrl', user.imageUrl ?? '');
      return user;
    } catch (_) {
      return null;
    }
  }

  // UPDATE PROFILE: kalau ganti password → hash ulang, dan hapus 'password' plaintext jika masih ada
  Future<void> updateProfile({
    String? newUsername,
    String? newPassword,
    File? newImageFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid == null) throw Exception('Not logged in');

    final db = FirebaseService.instance.db;
    final ref = db.collection(FirebaseService.instance.usersCol).doc(uid);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('User not found');
    final data = snap.data()!;

    String username = data['username'] ?? '';
    String? imageUrl = data['imageUrl'];

    if (newUsername != null && newUsername != username) {
      final exist = await db
          .collection(FirebaseService.instance.usersCol)
          .where('username', isEqualTo: newUsername)
          .limit(1)
          .get();
      if (exist.docs.isNotEmpty) {
        throw Exception('Username sudah digunakan');
      }
      username = newUsername;
    }

    if (newImageFile != null) {
      imageUrl = await StorageService.instance.uploadProfileImage(newImageFile, username);
    }

    final payload = <String, dynamic>{
      'username': username,
      'imageUrl': imageUrl,
      'updatedAt': DateTime.now(),
      // hapus 'password' kalau masih ada kebawa dari masa lalu
      'password': FieldValue.delete(),
    };

    if (newPassword != null && newPassword.length >= 4) {
      final salt = BCrypt.gensalt();
      final newHash = BCrypt.hashpw(newPassword, salt);
      payload['passwordHash'] = newHash;
    }

    await ref.update(payload);

    await prefs.setString('username', username);
    await prefs.setString('imageUrl', imageUrl ?? '');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, String?>> cachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username'),
      'role': prefs.getString('role'),
      'imageUrl': prefs.getString('imageUrl'),
      'uid': prefs.getString('uid'),
    };
  }

  // (Opsional) Utility sekali jalan: migrasi semua user legacy (punya 'password') -> passwordHash
  Future<int> migratePlaintextUsers() async {
    final db = FirebaseService.instance.db;
    final snap = await db.collection(FirebaseService.instance.usersCol).get();
    int cnt = 0;
    for (final d in snap.docs) {
      final data = d.data();
      final legacy = data['password'] as String?;
      final already = data['passwordHash'] as String?;
      if (legacy != null && (already == null || already.isEmpty)) {
        final salt = BCrypt.gensalt();
        final newHash = BCrypt.hashpw(legacy, salt);
        await db.collection(FirebaseService.instance.usersCol).doc(d.id).update({
          'passwordHash': newHash,
          'password': FieldValue.delete(),
          'updatedAt': DateTime.now(),
        });
        cnt++;
      }
    }
    return cnt;
  }
}
