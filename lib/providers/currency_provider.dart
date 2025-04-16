import 'package:flutter/material.dart';

class CurrencyProvider extends ChangeNotifier {
  // Default currency is Indian Rupee
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';
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
  String get currencyCode => _currencyCode;

  void setCurrency(String currencyCode) {
    if (availableCurrencies.containsKey(currencyCode)) {
      _currencySymbol = availableCurrencies[currencyCode]!;
      _currencyCode = currencyCode;
      notifyListeners();
    }
  }

  // Format an amount with the current currency symbol
  String format(double amount) {
    return '$_currencySymbol${amount.toStringAsFixed(2)}';
  }
}
