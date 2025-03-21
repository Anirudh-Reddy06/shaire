import 'package:supabase_flutter/supabase_flutter.dart';

class Notification {
  final int id;
  final String userId;
  final String type;
  final String content;
  final int? relatedEntityId;
  final String? relatedEntityType;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.relatedEntityId,
    this.relatedEntityType,
    required this.isRead,
    required this.createdAt,
  });

  /// Factory constructor to create Notification from JSON
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      relatedEntityId: json['related_entity_id'] as int?,
      relatedEntityType: json['related_entity_type'] as String?,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convert Notification to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'content': content,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class NotificationService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch a notification by ID
  Future<Notification?> fetchNotification(int id) async {
    try {
      final response = await supabase
          .from('notifications')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        print('No notification found for ID: $id');
        return null;
      }

      return Notification.fromJson(response);
    } catch (error) {
      print('Error fetching notification: $error');
      return null;
    }
  }

  /// Create a new notification
  Future<bool> createNotification(Notification notification) async {
    try {
      await supabase.from('notifications').insert(notification.toJson());
      print('Notification created successfully');
      return true;
    } catch (error) {
      print('Error creating notification: $error');
      return false;
    }
  }

  /// Update an existing notification
  Future<bool> updateNotification(Notification notification) async {
    try {
      await supabase
          .from('notifications')
          .update(notification.toJson())
          .eq('id', notification.id);

      print('Notification updated successfully');
      return true;
    } catch (error) {
      print('Error updating notification: $error');
      return false;
    }
  }

  /// Delete a notification by ID
  Future<bool> deleteNotification(int id) async {
    try {
      await supabase.from('notifications').delete().eq('id', id);
      print('Notification deleted successfully');
      return true;
    } catch (error) {
      print('Error deleting notification: $error');
      return false;
    }
  }
}
