import 'package:supabase_flutter/supabase_flutter.dart';

class Payment {
  final int id;
  final String paymentId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? notes;
  final String status;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.paymentId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      paymentId: json['payment_id'],
      fromUserId: json['from_user_id'],
      toUserId: json['to_user_id'],
      amount: (json['amount'] as num).toDouble(),  // Ensure double conversion
      currency: json['currency'],
      paymentMethod: json['payment_method'],
      paymentDate: DateTime.parse(json['payment_date']),
      notes: json['notes'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_id': paymentId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PaymentService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch a payment by ID
  Future<Payment?> fetchPayment(int id) async {
    try {
      final response = await supabase
          .from('payments')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        print('Payment not found');
        return null;
      }

      return Payment.fromJson(response);
    } catch (error) {
      print('Error fetching payment: $error');
      return null;
    }
  }

  /// Create a new payment
  Future<bool> createPayment(Payment payment) async {
    try {
      await supabase.from('payments').insert(payment.toJson());
      print('Payment created successfully');
      return true;
    } catch (error) {
      print('Error creating payment: $error');
      return false;
    }
  }

  /// Update an existing payment
  Future<bool> updatePayment(Payment payment) async {
    try {
      await supabase
          .from('payments')
          .update(payment.toJson())
          .eq('id', payment.id);

      print('Payment updated successfully');
      return true;
    } catch (error) {
      print('Error updating payment: $error');
      return false;
    }
  }

  /// Delete a payment by ID
  Future<bool> deletePayment(int id) async {
    try {
      await supabase.from('payments').delete().eq('id', id);
      print('Payment deleted successfully');
      return true;
    } catch (error) {
      print('Error deleting payment: $error');
      return false;
    }
  }
}
