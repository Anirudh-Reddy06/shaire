import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class Receipt {
  final int id;
  final String imageUrl;
  final DateTime createdAt;
  final int? expenseId;
  final String userId;

  Receipt({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    this.expenseId,
    required this.userId,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      expenseId: json['expense_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'expense_id': expenseId,
      'user_id': userId,
    };
  }
}

class ReceiptService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Upload a receipt image and create a receipt record in the database
  Future<Receipt?> uploadReceipt(File imageFile) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Generate a unique filename
      final uuid = const Uuid().v4();
      final fileExt = path.extension(imageFile.path);
      final fileName = 'receipt_$uuid$fileExt';

      // Upload file to storage
      final response = await supabase.storage
          .from('receipts')
          .upload('public/$fileName', imageFile);

      // Get the public URL
      final imageUrl =
          supabase.storage.from('receipts').getPublicUrl('public/$fileName');

      // Create receipt record in database
      final receiptData = {
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user.id,
      };

      final dbResponse =
          await supabase.from('receipts').insert(receiptData).select().single();

      return Receipt.fromJson(dbResponse);
    } catch (e) {
      print('Error uploading receipt: $e');
      return null;
    }
  }

  /// Link a receipt to an expense
  Future<bool> linkReceiptToExpense(int receiptId, int expenseId) async {
    try {
      await supabase
          .from('receipts')
          .update({'expense_id': expenseId}).eq('id', receiptId);
      return true;
    } catch (e) {
      print('Error linking receipt to expense: $e');
      return false;
    }
  }

  /// Get receipts for an expense
  Future<List<Receipt>> getReceiptsForExpense(int expenseId) async {
    try {
      final response =
          await supabase.from('receipts').select().eq('expense_id', expenseId);

      return response.map<Receipt>((json) => Receipt.fromJson(json)).toList();
    } catch (e) {
      print('Error getting receipts: $e');
      return [];
    }
  }
}
