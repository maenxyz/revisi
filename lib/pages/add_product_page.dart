import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import '../widgets/appbar_actions.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _name = TextEditingController();
  final _modelId = TextEditingController();
  final _materialId = TextEditingController();
  final _supplierId = TextEditingController();
  final _amount = TextEditingController();
  final _currentPrice = TextEditingController();
  final _oldPrice = TextEditingController();
  File? _image;
  bool _saving = false;

  Future<void> _pick(bool camera) async {
    final picker = ImagePicker();
    final x = await (camera ? picker.pickImage(source: ImageSource.camera) : picker.pickImage(source: ImageSource.gallery));
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _modelId.text.trim().isEmpty || _supplierId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, Model ID, Supplier ID wajib diisi')));
      return;
    }
    final amount = int.tryParse(_amount.text) ?? 0;
    final cp = int.tryParse(_currentPrice.text) ?? 0;
    final op = int.tryParse(_oldPrice.text) ?? 0;

    setState(() => _saving = true);
    await ProductService.instance.add(
      name: _name.text.trim(),
      modelId: _modelId.text.trim(),
      materialIdInput: _materialId.text,
      supplierId: _supplierId.text,
      amount: amount,
      currentPrice: cp,
      oldPrice: op,
      imageFile: _image,
    );
    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product'), actions: const [AppBarActions()]),
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
              child: AspectRatio(
                aspectRatio: 16/9,
                child: _image != null ? Image.file(_image!, fit: BoxFit.cover) : Container(
                  color: Colors.grey[300],
                  child: const Center(child: Text('Pilih Gambar (Ketuk)')),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _modelId, decoration: const InputDecoration(labelText: 'Model ID')),
            const SizedBox(height: 12),
            TextField(controller: _materialId, maxLength: 3, decoration: const InputDecoration(labelText: 'Material ID (0–3 char)')),
            const SizedBox(height: 12),
            TextField(controller: _supplierId, decoration: const InputDecoration(labelText: 'Supplier ID')),
            const SizedBox(height: 12),
            TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock (amount)')),
            const SizedBox(height: 12),
            TextField(controller: _currentPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Price')),
            const SizedBox(height: 12),
            TextField(controller: _oldPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Old Price')),
            const SizedBox(height: 16),
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
