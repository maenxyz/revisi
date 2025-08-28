// lib/pages/register_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  File? _image;
  bool _loading = false;

  Future<void> _pick(bool camera) async {
    final picker = ImagePicker();
    final x = await (camera
        ? picker.pickImage(source: ImageSource.camera)
        : picker.pickImage(source: ImageSource.gallery));
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _register() async {
    final username = _u.text.trim();
    final password = _p.text;
    //taudah w males buat 6 kwkw 4 ae ckp kykny sama (encryption gk jalan mulu jadi firestore passnya kgk di hash aowkwk)
    if (username.isEmpty || password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username wajib, password min 4')),
      );
      return;
    }
    setState(() => _loading = true);
    final err = await AuthService.instance
        .register(username: username, password: password, imageFile: _image);
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register berhasil. Silakan login.')),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16, // agak besar
        fontWeight: FontWeight.w700, // bold
      ),
    ),
  );

  InputDecoration _dec({String? hint}) => InputDecoration(
    hintText: hint,
    isDense: false,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 38), // tinggi
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar pilih foto
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final action = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Wrap(children: [
                            ListTile(
                              leading: const Icon(Icons.photo_camera),
                              title: const Text('Kamera'),
                              onTap: () => Navigator.pop(context, 'camera'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo),
                              title: const Text('Galeri'),
                              onTap: () => Navigator.pop(context, 'gallery'),
                            ),
                          ]),
                        ),
                      );
                      if (action == 'camera') await _pick(true);
                      if (action == 'gallery') await _pick(false);
                    },
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage:
                      _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? const Icon(Icons.person, size: 48)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Username
                _label('Username'),
                const SizedBox(height: 6),
                TextField(
                  controller: _u,
                  decoration: _dec(hint: 'Masukkan username'),
                ),
                const SizedBox(height: 24),

                // Password
                _label('Password'),
                const SizedBox(height: 6),
                TextField(
                  controller: _p,
                  decoration: _dec(hint: 'Masukkan password'),
                  obscureText: true,
                ),
                const SizedBox(height: 28),

                // Tombol Register (dipendekin & center)
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child:
                        CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Register'),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Link ke Login (underline)
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context)
                            .pushReplacementNamed('/login');
                      }
                    },
                    child: const Text(
                      'Sudah punya akun? Login',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
