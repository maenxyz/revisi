import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../widgets/appbar_actions.dart';
import '../widgets/rupiah_text.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
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

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    final product = args as ProductModel;

    final isAdmin = _role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Product Detail'), actions: const [AppBarActions()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16/16,

              child: product.imageURL != null && product.imageURL!.isNotEmpty
                  ? Image.network(product.imageURL!, fit: BoxFit.cover,height: 400,)
                  : Container(color: Colors.grey[300]),
            ),
            const SizedBox(height: 10),
            Center(child: Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            Center(child: Text('(${product.stockId})', style: const TextStyle(color: Colors.grey))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Price Before: '),
                RupiahText(product.oldPrice),
                const SizedBox(width: 16),
                const Text(' - After: '),
                RupiahText(product.currentPrice),
              ],
            ),
            const SizedBox(height: 12),
            Text('Stock: ${product.amount}'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _kv('ID Model', product.modelId),
            _kv('ID Bahan', product.materialId),
            _kv('ID Supplier', product.supplierId),
            const SizedBox(height: 24),
            if (isAdmin)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/product/edit', arguments: product),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus?'),
                            content: const Text('Yakin ingin menghapus produk ini?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                            ],
                          ),
                        ) ?? false;
                        if (yes) {
                          await ProductService.instance.delete(product.id);
                          if (!mounted) return;
                          Navigator.of(context).pop(); // back
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(v)),
      ],
    );
  }
}
