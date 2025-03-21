import 'package:supabase_flutter/supabase_flutter.dart';

class Balance {
  final int id;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final int? groupId;
  final DateTime lastUpdated;

  Balance({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    this.groupId,
    required this.lastUpdated,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      id: json['id'],
      fromUserId: json['from_user_id'],
      toUserId: json['to_user_id'],
      amount: (json['amount'] as num).toDouble(),  // Ensure double conversion
      currency: json['currency'],
      groupId: json['group_id'] as int?,  // Handle nullable int
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'currency': currency,
      'group_id': groupId,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class BalanceService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch a balance by `fromUserId` and `toUserId`
  Future<Balance?> fetchBalance(String fromUserId, String toUserId) async {
    try {
      final response = await supabase
          .from('balances')
          .select('*')
          .eq('from_user_id', fromUserId)
          .eq('to_user_id', toUserId)
          .maybeSingle();

      if (response == null) {
        print('No balance found');
        return null;
      }

      return Balance.fromJson(response);
    } catch (error) {
      print('Error fetching balance: $error');
      return null;
    }
  }

  /// Create a new balance
  Future<bool> createBalance(Balance balance) async {
    try {
      await supabase.from('balances').insert(balance.toJson());
      print('Balance created successfully');
      return true;
    } catch (error) {
      print('Error creating balance: $error');
      return false;
    }
  }

  /// Update an existing balance
  Future<bool> updateBalance(Balance balance) async {
    try {
      await supabase
          .from('balances')
          .update(balance.toJson())
          .eq('id', balance.id);

      print('Balance updated successfully');
      return true;
    } catch (error) {
      print('Error updating balance: $error');
      return false;
    }
  }

  /// Delete a balance by ID
  Future<bool> deleteBalance(int id) async {
    try {
      await supabase.from('balances').delete().eq('id', id);
      print('Balance deleted successfully');
      return true;
    } catch (error) {
      print('Error deleting balance: $error');
      return false;
    }
  }
}
