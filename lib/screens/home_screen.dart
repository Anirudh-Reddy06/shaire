import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
import '../providers/currency_provider.dart'; // Add this import

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildBalanceSection(context), // Pass context to access provider
          _buildRecentActivities(context), // Pass context to access provider
        ],
      ),
    );
  }

  Widget _buildBalanceSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildBalanceCard(context, 'You Get', 150.00, Colors.green),
          ),
          const SizedBox(width: 4), // Space between cards
          Expanded(
            child: _buildBalanceCard(context, 'You Owe', 75.00, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, String title, double amount, Color color) {
    // Access the currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(currencyProvider.format(amount), // Use the format method
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Recent Activities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildActivityItem(context, 'Dinner expense', 'You paid', 30.00,
                    Icons.restaurant),
                _buildActivityItem(
                    context, 'Movie tickets', 'John paid', 25.00, Icons.movie),
                _buildActivityItem(context, 'Groceries', 'You paid', 45.00,
                    Icons.shopping_cart),
                _buildActivityItem(context, 'Uber ride', 'Sarah paid', 15.00,
                    Icons.car_rental),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String action,
      double amount, IconData icon) {
    // Access the currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(action),
      trailing: Text(currencyProvider.format(amount), // Use the format method
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
