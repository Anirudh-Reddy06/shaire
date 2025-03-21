import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String username;
  final String? profilePhotoUrl;
  final String? firstname;
  final String? lastname;
  final String? mobileNumber;
  final String currency;
  final String? upiId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.username,
    this.profilePhotoUrl,
    this.firstname,
    this.lastname,
    this.mobileNumber,
    this.currency = 'INR',
    this.upiId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      profilePhotoUrl: json['profile_photo_url'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      mobileNumber: json['mobile_number'],
      currency: json['currency'] ?? 'INR', // Default currency if null
      upiId: json['upi_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profile_photo_url': profilePhotoUrl,
      'firstname': firstname,
      'lastname': lastname,
      'mobile_number': mobileNumber,
      'currency': currency,
      'upi_id': upiId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ProfileService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Profile?> fetchProfile(String username) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('username', username)
          .single(); // Fetch single row directly

      return Profile.fromJson(response);
    } catch (error) {
      print('Error fetching profile: $error');
      return null;
    }
  }

  Future<bool> createProfile(Profile profile) async {
    try {
      await supabase.from('profiles').insert(profile.toJson());
      print('Profile created successfully');
      return true;
    } catch (error) {
      print('Error creating profile: $error');
      return false;
    }
  }

  Future<bool> updateProfile(Profile profile) async {
    try {
      await supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('username', profile.username);
      print('Profile updated successfully');
      return true;
    } catch (error) {
      print('Error updating profile: $error');
      return false;
    }
  }

  Future<bool> deleteProfile(String username) async {
    try {
      await supabase.from('profiles').delete().eq('username', username);
      print('Profile deleted successfully');
      return true;
    } catch (error) {
      print('Error deleting profile: $error');
      return false;
    }
  }
}
