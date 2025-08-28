import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class UserModel {
  final String id; // Firestore docId
  final String username;
  final String password;
  final String role; // 'admin' | 'user'
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return null; // tipe lain diabaikan
    // kalau mau keras, bisa throw
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      username: (data['username'] ?? '').toString(),
      password: (data['password'] ?? '').toString(),
      role: (data['role'] ?? 'user').toString(),
      imageUrl: (data['imageUrl'] as String?),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
