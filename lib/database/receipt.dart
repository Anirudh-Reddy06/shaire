import 'package:supabase_flutter/supabase_flutter.dart';

class Receipt {
  final int id;
  final int expenseId;
  final String? imageUrl;
  final bool ocrProcessed;
  final dynamic ocrData;
  final DateTime? processedAt;

  Receipt({
    required this.id,
    required this.expenseId,
    this.imageUrl,
    required this.ocrProcessed,
    required this.ocrData,
    this.processedAt,
  });

  /// Factory constructor to create a Receipt from JSON
  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as int,
      expenseId: json['expense_id'] as int,
      imageUrl: json['image_url'] as String?,
      ocrProcessed: json['ocr_processed'] as bool,
      ocrData: json['ocr_data'],  // Dynamic field, no cast needed
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
    );
  }

  /// Convert the Receipt object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'image_url': imageUrl,
      'ocr_processed': ocrProcessed,
      'ocr_data': ocrData,
      'processed_at': processedAt?.toIso8601String(),
    };
  }
}

class ReceiptService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch a receipt by ID
  Future<Receipt?> fetchReceipt(int id) async {
    try {
      final response = await supabase
          .from('receipts')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        print('No receipt found for ID: $id');
        return null;
      }

      return Receipt.fromJson(response);
    } catch (error) {
      print('Error fetching receipt: $error');
      return null;
    }
  }

  /// Create a new receipt
  Future<bool> createReceipt(Receipt receipt) async {
    try {
      await supabase.from('receipts').insert(receipt.toJson());
      print('Receipt created successfully');
      return true;
    } catch (error) {
      print('Error creating receipt: $error');
      return false;
    }
  }

  /// Update an existing receipt
  Future<bool> updateReceipt(Receipt receipt) async {
    try {
      await supabase
          .from('receipts')
          .update(receipt.toJson())
          .eq('id', receipt.id);

      print('Receipt updated successfully');
      return true;
    } catch (error) {
      print('Error updating receipt: $error');
      return false;
    }
  }

  /// Delete a receipt by ID
  Future<bool> deleteReceipt(int id) async {
    try {
      await supabase.from('receipts').delete().eq('id', id);
      print('Receipt deleted successfully');
      return true;
    } catch (error) {
      print('Error deleting receipt: $error');
      return false;
    }
  }
}
