import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class GroupProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> fetchGroups() async {
    if (currentUserId == null) return;

    _isLoading = true;
    _error = null;
    // Consider removing immediate notifyListeners if it causes build errors
    // notifyListeners();

    try {
      // Fetch group IDs the user is a member of
      final memberRes = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', currentUserId!);

      final List<int> groupIds =
          memberRes.map<int>((m) => m['group_id'] as int).toList();

      if (groupIds.isNotEmpty) {
        // Fetch details for those groups
        // Also fetch member count for each group (example using count)
        final groupsRes = await _supabase
            .from('groups')
            .select(
                'id, name, description, created_at, group_members(count)') // Fetch member count
            .inFilter('id', groupIds);

        // Map the result to include member count directly
        _groups = groupsRes.map((group) {
          final memberCount =
              (group['group_members'] as List?)?.isNotEmpty ?? false
                  ? group['group_members'][0]['count']
                  : 0;
          return {
            'id': group['id'] as int,
            'name': group['name'],
            'description': group['description'],
            'created_at': group['created_at'],
            'member_count': memberCount,
          };
        }).toList();
      } else {
        _groups = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error fetching groups: $e");
      _error = "Failed to load groups data: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> createGroup(String name, String? description) async {
    if (currentUserId == null) throw Exception("Not logged in");
    if (name.trim().isEmpty) throw Exception("Group name cannot be empty");

    _isLoading = true;
    _error = null;
    notifyListeners();

    _logger.i("Creating group: $name");
    _logger.d("Description: ${description ?? '<none>'}");

    try {
      final insertRes = await _supabase
          .from('groups')
          .insert({
            'name': name.trim(),
            'description': description?.trim(),
            'created_by': currentUserId!,
          })
          .select('id')
          .single();
      final newGroupId = insertRes['id'] as int;

      _logger.i("Created group with ID: $newGroupId");

      // add creator as admin
      await _supabase.from('group_members').insert({
        'group_id': newGroupId,
        'user_id': currentUserId!,
        'role': 'admin',
      });
      _logger.i("Added creator $currentUserId as admin to $newGroupId");

      await fetchGroups();
      return newGroupId;
    } catch (e, st) {
      _logger.e("Failed to create group", error: e, stackTrace: st);
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMembersToGroup(int groupId, List<String> userIds) async {
    if (currentUserId == null) throw Exception('Not logged in');

    if (userIds.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();

      // Create a batch of records to insert
      final membersToAdd = userIds
          .map((userId) => {
                'group_id': groupId,
                'user_id': userId,
                'role': 'member',
                'joined_at': now
              })
          .toList();

      _logger.d('Adding ${membersToAdd.length} members to group $groupId');

      // Insert into group_members table
      await _supabase.from('group_members').insert(membersToAdd);
      _logger.i('Successfully added members to group $groupId');

      await fetchGroups(); // Refresh the groups data
    } catch (e) {
      _error = e.toString();
      _logger.e('Error adding members: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinGroup(String inviteCode) async {
    final userId = currentUserId; // Store in local variable
    if (userId == null) throw Exception('Not logged in');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.d('Joining group with code: "${inviteCode.trim()}"');

      final results = await _supabase
          .from('groups')
          .select('id')
          .eq('invite_code', inviteCode.trim());

      if (results.isEmpty) {
        throw Exception('Invalid invite code. Please check and try again.');
      }

      final groupId = results[0]['id'];
      _logger.d('Found group with ID: $groupId');

      final existingCheck = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId);

      if (existingCheck.isNotEmpty) {
        throw Exception('You are already a member of this group.');
      }

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });

      _logger.i('Successfully joined group with ID: $groupId');
      await fetchGroups();
    } catch (e) {
      _error = e.toString();
      _logger.e('Error joining group: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add fetchGroupMembers, addMember, leaveGroup etc. as needed for details screen
}
