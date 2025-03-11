import 'package:flutter/material.dart';

class CurrencyProvider extends ChangeNotifier {
  // Default currency is Indian Rupee
  String _currencySymbol = '₹';

  // Common currency symbols
  static const Map<String, String> availableCurrencies = {
    'INR': '₹', // Indian Rupee (default)
    'USD': '\$', // US Dollar
    'EUR': '€', // Euro
    'GBP': '£', // British Pound
    'JPY': '¥', // Japanese Yen
    'AUD': 'A\$', // Australian Dollar
    'CAD': 'C\$', // Canadian Dollar
  };

  String get currencySymbol => _currencySymbol;

  void setCurrency(String currencyCode) {
    if (availableCurrencies.containsKey(currencyCode)) {
      _currencySymbol = availableCurrencies[currencyCode]!;
      notifyListeners();
    }
  }

  // Format an amount with the current currency symbol
  String format(double amount) {
    return '$_currencySymbol${amount.toStringAsFixed(2)}';
  }
}
