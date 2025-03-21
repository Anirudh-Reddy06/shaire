import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/groups.dart';  // Import your Group model

class GroupProvider with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Group> _groups = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;

  /// Fetch all groups from Supabase
  Future<void> fetchGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await supabase.from('groups').select('*').order('created_at', ascending: false);

      _groups = response.map<Group>((json) => Group.fromJson(json)).toList();
    } catch (error) {
      print('Error fetching groups: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single group by ID
  Future<Group?> fetchGroupById(int id) async {
    try {
      final response = await supabase
          .from('groups')
          .select('*')
          .eq('id', id)
          .single();
      
      return Group.fromJson(response);
    } catch (error) {
      print('Error fetching group by ID: $error');
      return null;
    }
  }

  /// Create a new group
  Future<void> createGroup(Group group) async {
    try {
      await supabase.from('groups').insert(group.toJson());
      await fetchGroups();  // Refresh groups after creation
    } catch (error) {
      print('Error creating group: $error');
    }
  }

  /// Update an existing group
  Future<void> updateGroup(Group group) async {
    try {
      await supabase.from('groups').update(group.toJson()).eq('id', group.id);
      await fetchGroups();  // Refresh groups after update
    } catch (error) {
      print('Error updating group: $error');
    }
  }

  /// Delete a group by ID
  Future<void> deleteGroup(int id) async {
    try {
      await supabase.from('groups').delete().eq('id', id);
      _groups.removeWhere((group) => group.id == id);
      notifyListeners();
    } catch (error) {
      print('Error deleting group: $error');
    }
  }

  /// Clear groups (optional helper function)
  void clearGroups() {
    _groups = [];
    notifyListeners();
  }
}
