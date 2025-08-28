import 'package:intl/intl.dart';

class FormatService {
  static final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static String rupiah(num n) => _idr.format(n);
}
