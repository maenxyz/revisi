// lib/pages/search_page.dart
import 'package:flutter/material.dart';
import '../widgets/appbar_actions.dart';
import '../widgets/range_inputs.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controllers
  final _modelId = TextEditingController();
  final _materialId = TextEditingController();
  final _supplierId = TextEditingController();

  final _priceMin = TextEditingController();
  final _priceMax = TextEditingController();
  final _stockMin = TextEditingController();
  final _stockMax = TextEditingController();

  // States
  bool _priceChanged = false;
  bool _loading = false;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final c = await AuthService.instance.cachedProfile();
    setState(() => _role = (c['role'] ?? 'user')!);
  }

  void _reset() {
    _modelId.clear();
    _materialId.clear();
    _supplierId.clear();
    _priceMin.clear();
    _priceMax.clear();
    _stockMin.clear();
    _stockMax.clear();
    setState(() => _priceChanged = false);
  }
  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final results = await ProductService.instance.search(
        modelId: _modelId.text.trim().isEmpty ? null : _modelId.text.trim(),
        materialIdInput: _materialId.text,
        supplierId: _supplierId.text,
        priceMin: _priceMin.text.isEmpty ? null : int.tryParse(_priceMin.text),
        priceMax: _priceMax.text.isEmpty ? null : int.tryParse(_priceMax.text),
        stockMin: _stockMin.text.isEmpty ? null : int.tryParse(_stockMin.text),
        stockMax: _stockMax.text.isEmpty ? null : int.tryParse(_stockMax.text),
        priceChanged: _priceChanged,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushNamed('/results', arguments: results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencari: $e')),
      );
    }
  }


  // Label helper: bold & kiri
  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isAdmin = _role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/product/add'),
        child: const Icon(Icons.add),
      )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ID Model
            _label('ID Model'),
            const SizedBox(height: 6),
            TextField(
              controller: _modelId,
              decoration: const InputDecoration(labelText: 'Model ID'),
            ),
            const SizedBox(height: 12),

            // ID Bahan
            _label('ID Bahan'),
            const SizedBox(height: 6),
            TextField(
              controller: _materialId,
              maxLength: 3,
              decoration:
              const InputDecoration(labelText: 'Material ID (0–3 char)'),
            ),
            const SizedBox(height: 12),

            // ID Supplier
            _label('ID Supplier'),
            const SizedBox(height: 6),
            TextField(
              controller: _supplierId,
              decoration: const InputDecoration(labelText: 'Supplier ID'),
            ),
            const SizedBox(height: 12),

            // Harga (range)
            _label('Harga'),
            const SizedBox(height: 6),
            RangeInputs(
              minCtrl: _priceMin,
              maxCtrl: _priceMax,
              labelMin: 'Harga Min',
              labelMax: 'Harga Max',
            ),
            const SizedBox(height: 12),

            // Stock (range)
            _label('Stock'),
            const SizedBox(height: 6),
            RangeInputs(
              minCtrl: _stockMin,
              maxCtrl: _stockMax,
              labelMin: 'Stock Min',
              labelMax: 'Stock Max',
            ),
            const SizedBox(height: 12),

            // Price Changed
            CheckboxListTile(
              value: _priceChanged,
              onChanged: (v) => setState(() => _priceChanged = v ?? false),
              title: const Text('Price Changed'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _search,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Search'),
              ),
            ),
            TextButton(
              onPressed: _reset,
              child: const Text('Reset to Default'),
            ),
          ],
        ),
      ),
    );
  }
}
