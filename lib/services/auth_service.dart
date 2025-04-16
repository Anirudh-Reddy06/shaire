import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Sign out function
  Future<void> signOut(BuildContext context) async {
    try {
      // Clear cached user data
      await Provider.of<UserProvider>(context, listen: false).clearCache();

      // Sign out from Supabase
      await supabase.auth.signOut();

      // Clear navigation stack and go to splash screen
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
}
