import 'package:flutter/services.dart';

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = _addThousandsSeparator(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addThousandsSeparator(String digits) {
    if (digits.length <= 3) return digits;

    final buffer = StringBuffer();
    final remainder = digits.length % 3;

    if (remainder > 0) {
      buffer.write(digits.substring(0, remainder));
      if (digits.length > remainder) buffer.write('.');
    }

    for (var i = remainder; i < digits.length; i += 3) {
      if (i > remainder) buffer.write('.');
      buffer.write(digits.substring(i, i + 3));
    }

    return buffer.toString();
  }
}
