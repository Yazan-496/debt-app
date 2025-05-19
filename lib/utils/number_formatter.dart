class NumberFormatter {
  static String formatPrice(dynamic price) {
    if (price == null) return '0';
    final number = double.parse(price.toString());
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
