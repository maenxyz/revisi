import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/appbar_actions.dart';

class EditProductPage extends StatefulWidget {
  const EditProductPage({super.key});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _name = TextEditingController();
  final _modelId = TextEditingController();
  final _materialId = TextEditingController();
  final _supplierId = TextEditingController();
  final _amount = TextEditingController();
  final _currentPrice = TextEditingController();
  final _oldPrice = TextEditingController();
  File? _newImage;
  bool _saving = false;
  late ProductModel prod;

  @override
  void initState() {
    super.initState();
    // controller diisi saat build menggunakan args
  }

  Future<void> _pick(bool camera) async {
    final picker = ImagePicker();
    final x = await (camera ? picker.pickImage(source: ImageSource.camera) : picker.pickImage(source: ImageSource.gallery));
    if (x != null) setState(() => _newImage = File(x.path));
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text) ?? 0;
    final cp = int.tryParse(_currentPrice.text) ?? 0;
    final op = int.tryParse(_oldPrice.text) ?? 0;

    setState(() => _saving = true);
    await ProductService.instance.update(
      docId: prod.id,
      name: _name.text.trim(),
      modelId: _modelId.text.trim(),
      materialIdInput: _materialId.text,
      supplierId: _supplierId.text,
      amount: amount,
      currentPrice: cp,
      oldPrice: op,
      stockId: prod.stockId,
      newImageFile: _newImage,
    );
    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    prod = ModalRoute.of(context)!.settings.arguments as ProductModel;
    _name.text = _name.text.isEmpty ? prod.name : _name.text;
    _modelId.text = _modelId.text.isEmpty ? prod.modelId : _modelId.text;
    _materialId.text = _materialId.text.isEmpty ? prod.materialId.trimRight() : _materialId.text; // show w/o right spaces
    _supplierId.text = _supplierId.text.isEmpty ? prod.supplierId : _supplierId.text;
    _amount.text = _amount.text.isEmpty ? '${prod.amount}' : _amount.text;
    _currentPrice.text = _currentPrice.text.isEmpty ? '${prod.currentPrice}' : _currentPrice.text;
    _oldPrice.text = _oldPrice.text.isEmpty ? '${prod.oldPrice}' : _oldPrice.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product'), actions: const [AppBarActions()]),
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
                child: _newImage != null
                    ? Image.file(_newImage!, fit: BoxFit.cover)
                    : (prod.imageURL != null && prod.imageURL!.isNotEmpty
                    ? Image.network(prod.imageURL!, fit: BoxFit.cover)
                    : Container(color: Colors.grey[300], child: const Center(child: Text('Pilih Gambar (Ketuk)')))),
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
                child: _saving ? const CircularProgressIndicator() : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
