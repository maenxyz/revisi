import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../widgets/appbar_actions.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  File? _image;
  bool _saving = false;
  String? _currentImage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await AuthService.instance.cachedProfile();
    setState(() {
      _u.text = (c['username'] ?? '')!;
      _currentImage = c['imageUrl'];
    });
  }

  Future<void> _pick(bool camera) async {
    final picker = ImagePicker();
    final x = await (camera ? picker.pickImage(source: ImageSource.camera) : picker.pickImage(source: ImageSource.gallery));
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _save() async {
    if (_u.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username wajib')));
      return;
    }
    if (_p.text.isNotEmpty && _p.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 4 karakter')));
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateProfile(
        newUsername: _u.text.trim(),
        newPassword: _p.text.isEmpty ? null : _p.text,
        newImageFile: _image,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _image != null
        ? Image.file(_image!, fit: BoxFit.cover)
        : (_currentImage != null && _currentImage!.isNotEmpty
        ? Image.network(_currentImage!, fit: BoxFit.cover)
        : const Icon(Icons.person, size: 40));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), actions: const [AppBarActions()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final a = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(children: [
                      ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Kamera'), onTap: () => Navigator.pop(context, 'camera')),
                      ListTile(leading: const Icon(Icons.photo), title: const Text('Galeri'), onTap: () => Navigator.pop(context, 'gallery')),
                    ]),
                  ),
                );
                if (a == 'camera') await _pick(true);
                if (a == 'gallery') await _pick(false);
              },
              child: CircleAvatar(
                radius: 40,
                child: ClipOval(child: SizedBox(width: 80, height: 80, child: Center(child: avatar))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _u, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            TextField(controller: _p, decoration: const InputDecoration(labelText: 'Password (biarkan kosong jika tidak ganti)'), obscureText: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator() : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
