import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaire/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/currency_provider.dart';
import '../providers/user_provider.dart';
import 'edit_profile_screen.dart';
import 'edit_payment_info_screen.dart';

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
    _loadProfile();
  }

  void _loadProfile() {
    // Use the provider method which handles caching
    _userProfileFuture =
        Provider.of<UserProvider>(context, listen: false).getUserProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      // Use the provider method for refreshing
      _userProfileFuture = Provider.of<UserProvider>(context, listen: false)
          .refreshUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method using Consumer and FutureBuilder remains the same) ...
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final profileData = userProvider.userData;

            if (userProvider.isLoading && profileData == null) {
              return const Center(child: CircularProgressIndicator());
            } else if (!userProvider.isLoading && profileData == null) {
              return _buildErrorWidget("Failed to load profile.");
            } else if (profileData != null) {
              return _buildProfileContent(profileData);
            } else {
              return FutureBuilder<Map<String, dynamic>>(
                future: _userProfileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error.toString());
                  } else if (snapshot.hasData) {
                    return _buildProfileContent(snapshot.data!);
                  } else {
                    return const Center(child: Text('No profile data found.'));
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }

  // Extracted profile content widget (remains the same)
  Widget _buildProfileContent(Map<String, dynamic> userData) {
    // ... (ListView with calls to _buildProfilePhoto, _buildProfileInfo, _buildPaymentInfo) ...
    return ListView(
      // Use ListView for natural scrolling with RefreshIndicator
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 16), // Add some top padding
        _buildProfilePhoto(userData),
        const SizedBox(height: 24),
        _buildProfileInfo(userData),
        const SizedBox(height: 24),
        _buildPaymentInfo(context, userData),
        const SizedBox(height: 40), // Add space at the bottom
      ],
    );
  }

  // --- ADD FULL IMPLEMENTATION HERE ---
  // Extracted error widget
  Widget _buildErrorWidget(String errorMsg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading profile: $errorMsg',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshProfile, // Use refresh function
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // --- ADD FULL IMPLEMENTATION HERE ---
  // Profile Photo Widget
  Widget _buildProfilePhoto(Map<String, dynamic> userData) {
    final String? avatarUrl = userData['avatar_url'];
    // Basic placeholder logic
    final String initials =
        (userData['full_name'] ?? userData['username'] ?? '?')
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return CircleAvatar(
      radius: 60,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(initials,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))
          : null,
    );
  }

  // Profile Info Card (remains the same)
  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    // ... (Card with Name, Username, Mobile Number) ...
    final String fullName = userData['full_name'] ?? 'Not set';
    final String username = userData['username'] ?? 'Not set';
    final String phone = userData['phone'] ?? 'Not set';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 20.0), // Adjust padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Information',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)), // Bolder title
            const SizedBox(height: 16), // Space before first item
            _buildInfoRow('Name', fullName),
            _buildInfoRow('Username', username),
            _buildInfoRow('Mobile Number', phone),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Profile'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfileScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Payment Info Card (remains the same)
  Widget _buildPaymentInfo(
      BuildContext context, Map<String, dynamic> userData) {
    // ... (Card with Default Currency, UPI ID) ...
    final String defaultCurrencyCode = userData['currency'] ?? 'INR';
    final String defaultCurrencySymbol =
        CurrencyProvider.availableCurrencies[defaultCurrencyCode] ?? '₹';
    final String upiId = userData['upi_id'] ?? 'Not set';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 20.0), // Adjust padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Information',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)), // Bolder title
            const SizedBox(height: 16), // Space before first item
            _buildInfoRow('Default Currency',
                '$defaultCurrencyCode ($defaultCurrencySymbol)'),
            _buildInfoRow('UPI ID', upiId),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Payment Info'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditPaymentInfoScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info Row Helper (remains the same)
  Widget _buildInfoRow(String label, String value) {
    // ... (Row with Label and Value) ...
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
      // Redirect to root route (SplashScreen) which will handle auth state properly
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
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
