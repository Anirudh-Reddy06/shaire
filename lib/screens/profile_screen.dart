import 'package:flutter/material.dart';
import 'package:shaire/theme/theme.dart';
import 'package:provider/provider.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfilePhoto(),
            const SizedBox(height: 24),
            _buildProfileInfo(),
            const SizedBox(height: 24),
            _buildPaymentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: 80, color: Colors.grey[600]),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Name', 'John Doe'),
            _buildInfoRow('Username', '@johndoe'),
            _buildInfoRow('Mobile Number', '+1 234 567 8900'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to edit profile screen
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Currency', 'USD'),
            _buildInfoRow('UPI ID', 'johndoe@upi'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to edit payment info screen
              },
              child: const Text('Edit Payment Info'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Dark Theme'),
            trailing: Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, child) {
                return Switch(
                  value: themeNotifier.themeMode == ThemeMode.dark,
                  onChanged: (isDark) {
                    themeNotifier.toggleTheme();
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sign Out'),
            onTap: () {
              // TODO: Implement sign out logic
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Sign Out'),
                        onPressed: () {
                          // TODO: Implement actual sign out logic
                          Navigator.of(context).pop();
                          // Navigate back to login screen or home
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}


