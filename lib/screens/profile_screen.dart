import 'package:flutter/material.dart';
import 'package:shaire/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/currency_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userProfileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading profile: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _userProfileFuture = fetchUserProfile();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              final userData = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfilePhoto(userData),
                  const SizedBox(height: 24),
                  _buildProfileInfo(userData),
                  const SizedBox(height: 24),
                  _buildPaymentInfo(context, userData),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(Map<String, dynamic> userData) {
    final String? avatarUrl = userData['avatar_url'];

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Icon(Icons.person, size: 80, color: Colors.grey[600])
          : null,
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    final String fullName = userData['full_name'] ?? 'Not set';
    final String username = userData['username'] ?? 'Not set';
    final String phone = userData['phone'] ?? 'Not set';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Name', fullName),
            _buildInfoRow('Username', username),
            _buildInfoRow('Mobile Number', phone),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile coming soon')),
                );
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(
      BuildContext context, Map<String, dynamic> userData) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final String upiId = userData['upi_id'] ?? 'Not set';

    // Find which currency code matches the current symbol
    final String currencyCode = CurrencyProvider.availableCurrencies.entries
        .firstWhere((entry) => entry.value == currencyProvider.currencySymbol,
            orElse: () => const MapEntry('INR', '₹'))
        .key;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Currency dropdown with current value
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Currency',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: currencyCode,
                    items: CurrencyProvider.availableCurrencies.entries
                        .map((entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text("${entry.key} (${entry.value})"),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        currencyProvider.setCurrency(newValue);
                      }
                    },
                  ),
                ],
              ),
            ),

            _buildInfoRow('UPI ID', upiId),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to edit payment info screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Edit payment info coming soon')),
                );
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
  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

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
          // Add currency selector in settings
          Consumer<CurrencyProvider>(
            builder: (context, currencyProvider, child) {
              // Find current currency code
              final String currencyCode = CurrencyProvider
                  .availableCurrencies.entries
                  .firstWhere(
                      (entry) => entry.value == currencyProvider.currencySymbol,
                      orElse: () => const MapEntry('INR', '₹'))
                  .key;

              return ListTile(
                leading: const Icon(Icons.currency_exchange),
                title: const Text('Currency'),
                subtitle: Text(
                    'Current: $currencyCode (${currencyProvider.currencySymbol})'),
                trailing: PopupMenuButton<String>(
                  onSelected: (String currency) {
                    currencyProvider.setCurrency(currency);
                  },
                  itemBuilder: (BuildContext context) {
                    return CurrencyProvider.availableCurrencies.entries
                        .map((entry) => PopupMenuItem<String>(
                              value: entry.key,
                              child: Text("${entry.key} (${entry.value})"),
                            ))
                        .toList();
                  },
                ),
              );
            },
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
                          _signOut(context);
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

Future<Map<String, dynamic>> fetchUserProfile() async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    throw Exception('No user is logged in');
  }

  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  } catch (error) {
    if (error is PostgrestException) {
      throw Exception(error.message);
    } else {
      throw Exception('Unexpected error occurred');
    }
  }
}

Future<void> updateUserProfile(Map<String, dynamic> updates) async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    throw Exception('No user is logged in');
  }

  updates['updated_at'] = DateTime.now().toIso8601String();

  final response = await Supabase.instance.client
      .from('profiles')
      .update(updates)
      .eq('id', user.id);

  if (response.error != null) {
    throw Exception(response.error!.message);
  }
}
