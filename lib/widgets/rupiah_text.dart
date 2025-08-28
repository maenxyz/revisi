import 'package:flutter/material.dart';
import '../services/format_service.dart';

class RupiahText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  const RupiahText(this.value, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(FormatService.rupiah(value), style: style);
  }
}
