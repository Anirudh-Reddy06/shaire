import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../services/logger_service.dart';

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
      // Make sure id is not null before using it
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

  /// Upload a receipt image and save to database
  Future<Receipt?> uploadReceipt(File imageFile) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        LoggerService.error('User not authenticated');
        throw Exception('User not authenticated');
      }

      // Compress the image first
      LoggerService.info('Compressing receipt image');
      final compressedFile = await _compressImage(imageFile);

      // Generate a unique file name
      final fileExt = path.extension(imageFile.path);
      final fileName = '${const Uuid().v4()}$fileExt';

      // Upload to Supabase Storage
      LoggerService.info('Uploading receipt to storage: ${user.id}/$fileName');
      await supabase.storage
          .from('receipts')
          .upload('${user.id}/$fileName', compressedFile);

      // Get public URL for the uploaded file
      final imageUrl = supabase.storage
          .from('receipts')
          .getPublicUrl('${user.id}/$fileName');
      LoggerService.info('Receipt image URL: $imageUrl');

      // Create receipt record in database
      final now = DateTime.now();
      final receiptData = {
        'image_url': imageUrl,
        'created_at': now.toIso8601String(),
        'user_id': user.id
      };

      LoggerService.info('Creating receipt record in database');
      final result =
          await supabase.from('receipts').insert(receiptData).select().single();

      LoggerService.info('Receipt created with ID: ${result['id']}');
      return Receipt.fromJson(result);
    } catch (e) {
      LoggerService.error('Error uploading receipt', e);
      return null;
    }
  }

  // Compress image to reduce size
  Future<File> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

    try {
      // Log original file size
      LoggerService.debug('Original image size: ${file.lengthSync()} bytes');

      // Compress the file
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
      );

      // Check if compression was successful
      if (result != null) {
        // Convert XFile to File and check size
        final compressedFile = File(result.path);
        LoggerService.debug(
            'Compressed image size: ${compressedFile.lengthSync()} bytes');
        return compressedFile;
      } else {
        LoggerService.warning('Compression failed, using original file');
        return file;
      }
    } catch (e) {
      LoggerService.error('Error during compression', e);
      return file; // Return original file on error
    }
  }

  /// Link a receipt with an expense
  Future<bool> linkReceiptToExpense(int receiptId, int expenseId) async {
    try {
      LoggerService.info('Linking receipt $receiptId to expense $expenseId');
      await supabase
          .from('receipts')
          .update({'expense_id': expenseId}).eq('id', receiptId);
      return true;
    } catch (e) {
      LoggerService.error('Error linking receipt to expense', e);
      return false;
    }
  }
}
