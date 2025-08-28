import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'rupiah_text.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar dipaksa square supaya seragam
            AspectRatio(
              aspectRatio: 1,
              child: product.imageURL != null && product.imageURL!.isNotEmpty
                  ? Image.network(product.imageURL!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300]),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: _Info(product: product),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final ProductModel product;
  const _Info({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Batasi ke 1 baris supaya tidak nambah tinggi tak terduga
        Text(
          'ID Barang: ${product.stockId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        // Harga & stock sudah single-line
        RupiahText(product.currentPrice, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        Text('Stock: ${product.amount} pcs'),
      ],
    );
  }
}
