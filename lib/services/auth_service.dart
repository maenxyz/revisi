import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<UserModel?> login(String username, String password) async {
    try {
      final db = FirebaseService.instance.db;

      // Query 1 field saja (username) → hindari composite index & error
      final q = await db
          .collection(FirebaseService.instance.usersCol)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return null;

      final d = q.docs.first;
      final data = d.data(); // Map<String, dynamic>
      final user = UserModel.fromMap(d.id, data);

      // Manual verify password (manual auth)
      if (user.password != password) return null;

      // Cache session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', user.id);
      await prefs.setString('username', user.username);
      await prefs.setString('role', user.role);
      await prefs.setString('imageUrl', user.imageUrl ?? '');

      return user;
    } catch (e) {
      // Lempar lagi biar UI bisa nampilin error & hentikan spinner
      rethrow;
    }
  }

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

    final now = DateTime.now();
    await db.collection(FirebaseService.instance.usersCol).add({
      'username': username,
      'password': password,
      'role': role,
      'imageUrl': imageUrl,
      'createdAt': now,
      'updatedAt': now,
    });

    return null; // null = sukses
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
      // refresh cache
      await prefs.setString('username', user.username);
      await prefs.setString('role', user.role);
      await prefs.setString('imageUrl', user.imageUrl ?? '');
      return user;
    } catch (_) {
      // Kalau gagal (offline/rules), anggap belum login
      return null;
    }
  }

  Future<void> updateProfile({
    String? newUsername,
    String? newPassword,
    File? newImageFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid == null) throw Exception('Not logged in');

    final db = FirebaseService.instance.db;
    final snap = await db.collection(FirebaseService.instance.usersCol).doc(uid).get();
    if (!snap.exists) throw Exception('User not found');
    final data = snap.data()!;
    String username = data['username'];
    String password = data['password'];
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
    if (newPassword != null && newPassword.length >= 4) {
      password = newPassword;
    }
    if (newImageFile != null) {
      imageUrl = await StorageService.instance.uploadProfileImage(newImageFile, username);
    }

    final now = DateTime.now();
    await db.collection(FirebaseService.instance.usersCol).doc(uid).update({
      'username': username,
      'password': password,
      'imageUrl': imageUrl,
      'updatedAt': now,
    });

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
}
