class PadService {
  /// Model ID normalizer:
  /// - Jika semua digit dan panjang <= 3 → pad kiri '0' ke panjang 3 (contoh: "0" -> "000", "12" -> "012").
  /// - Selain itu, pakai apa adanya.
  static String normalizeModelId(String input) {
    final t = input.trim();
    final isDigits = RegExp(r'^\d+$').hasMatch(t);
    if (isDigits && t.length <= 3) return t.padLeft(3, '0');
    return t;
  }

  /// SIMPAN (Add/Edit): material harus tepat 3 karakter.
  /// - Tidak di-trim sama sekali (supaya spasi depan/belakang dipertahankan).
  /// - Jika < 3 → pad sesuai pola:
  ///    * kalau diawali spasi → padLeft(3, ' ')
  ///    * selain itu → padRight(3, ' ')
  /// - Jika > 3 → potong ke 3.
  static String padMaterialForStore(String input) {
    var s = input; // jangan trim!
    if (s.length >= 3) return s.substring(0, 3);
    if (s.startsWith(' ')) return s.padLeft(3, ' ');
    return s.padRight(3, ' ');
  }

  /// SEARCH: sama aturan padding, tapi kalau kosong → abaikan filter (return null).
  static String? padMaterialForSearch(String input) {
    var s = input; // jangan trim!
    if (s.isEmpty) return null;
    if (s.length >= 3) return s.substring(0, 3);
    if (s.startsWith(' ')) return s.padLeft(3, ' ');
    return s.padRight(3, ' ');
  }
}
