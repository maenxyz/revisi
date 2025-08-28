import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/appbar_actions.dart';

class SearchListPage extends StatelessWidget {
  const SearchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    final items = (args is List<ProductModel>) ? args : <ProductModel>[];

    const crossAxisCount = 2;
    const spacing = 12.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Search Results'), actions: const [AppBarActions()]),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Lebar 1 kartu dalam grid
          final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

          // Gambar square -> tinggi = itemWidth
          // Tambahkan tinggi area teks (perkiraan) supaya cukup:
          // (padding 10*2) + 3 baris teks ~ 18*3 + jarak 6*2 ≈ ~90–110
          // Pakai 110 agar aman untuk font besar/locale.
          const textAreaHeight = 110.0;

          // childAspectRatio = width / height
          final childAspectRatio = itemWidth / (itemWidth + textAreaHeight);

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (_, i) => ProductCard(
                product: items[i],
                onTap: () => Navigator.of(context).pushNamed('/product', arguments: items[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}
