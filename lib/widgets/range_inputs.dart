import 'package:flutter/material.dart';

class RangeInputs extends StatelessWidget {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final String labelMin;
  final String labelMax;
  const RangeInputs({
    super.key,
    required this.minCtrl,
    required this.maxCtrl,
    required this.labelMin,
    required this.labelMax,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: TextField(
          controller: minCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: labelMin),
        )),
        const SizedBox(width: 12),
        Expanded(child: TextField(
          controller: maxCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: labelMax),
        )),
      ],
    );
  }
}
