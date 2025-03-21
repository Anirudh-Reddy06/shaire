import 'package:supabase_flutter/supabase_flutter.dart';

class Expense {
  final int id;
  final String description;
  final double totalAmount;
  final String currency;
  final DateTime date;
  final String createdBy;
  final int? groupId;
  final int? categoryId;
  final String? receiptImageUrl;
  final String splitType;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.currency,
    required this.date,
    required this.createdBy,
    this.groupId,
    this.categoryId,
    this.receiptImageUrl,
    required this.splitType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      description: json['description'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'],
      date: DateTime.parse(json['date']),
      createdBy: json['created_by'],
      groupId: json['group_id'],
      categoryId: json['category_id'],
      receiptImageUrl: json['receipt_image_url'],
      splitType: json['split_type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'total_amount': totalAmount,
      'currency': currency,
      'date': date.toIso8601String(),
      'created_by': createdBy,
      'group_id': groupId,
      'category_id': categoryId,
      'receipt_image_url': receiptImageUrl,
      'split_type': splitType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ExpenseService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch an expense by ID
  Future<Expense?> fetchExpense(int id) async {
    try {
      final response = await supabase
          .from('expenses')
          .select('*')
          .eq('id', id)
          .maybeSingle();  // Fetch single or return null

      if (response == null) {
        print('Expense not found');
        return null;
      }
      return Expense.fromJson(response);
    } catch (error) {
      print('Error fetching expense: $error');
      return null;
    }
  }

  /// Create a new expense
  Future<bool> createExpense(Expense expense) async {
    try {
      await supabase.from('expenses').insert(expense.toJson());
      print('Expense created successfully');
      return true;
    } catch (error) {
      print('Error creating expense: $error');
      return false;
    }
  }

  /// Update an existing expense
  Future<bool> updateExpense(Expense expense) async {
    try {
      await supabase
          .from('expenses')
          .update(expense.toJson())
          .eq('id', expense.id);

      print('Expense updated successfully');
      return true;
    } catch (error) {
      print('Error updating expense: $error');
      return false;
    }
  }

  /// Delete an expense by ID
  Future<bool> deleteExpense(int id) async {
    try {
      await supabase.from('expenses').delete().eq('id', id);
      print('Expense deleted successfully');
      return true;
    } catch (error) {
      print('Error deleting expense: $error');
      return false;
    }
  }
}
