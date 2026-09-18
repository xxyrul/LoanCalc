import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input live with commas (e.g. 500000 -> 500,000)
/// while intelligently preserving the cursor position.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Strip everything except digits
    final String cleanDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int? val = int.tryParse(cleanDigits);
    if (val == null) {
      return oldValue;
    }

    final String formatted = _formatter.format(val);

    // Count how many raw digits occurred before the cursor in newValue
    int digitsBeforeCursor = 0;
    final int selectionEnd = newValue.selection.end.clamp(0, newValue.text.length);
    for (int i = 0; i < selectionEnd; i++) {
      if (RegExp(r'[0-9]').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    // Calculate new cursor position in formatted string
    int newCursorPos = 0;
    int countedDigits = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        countedDigits++;
      }
      if (countedDigits >= digitsBeforeCursor) {
        newCursorPos = i + 1;
        break;
      }
    }

    if (digitsBeforeCursor == 0) {
      newCursorPos = 0;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPos.clamp(0, formatted.length),
      ),
    );
  }
}
