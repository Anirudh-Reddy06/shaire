import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/expense.dart';  // Import the Expense model

class ExpenseProvider with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  /// Fetch all expenses
  Future<void> fetchExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('expenses')
          .select('*')
          .order('date', ascending: false);

      _expenses = response.map<Expense>((json) => Expense.fromJson(json)).toList();
    } catch (error) {
      print('Error fetching expenses: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single expense by ID
  Future<Expense?> fetchExpenseById(int id) async {
    try {
      final response = await supabase
          .from('expenses')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        print('Expense not found');
        return null;
      }

      return Expense.fromJson(response);
    } catch (error) {
      print('Error fetching expense by ID: $error');
      return null;
    }
  }

  /// Create a new expense
  Future<void> createExpense(Expense expense) async {
    try {
      await supabase.from('expenses').insert(expense.toJson());
      await fetchExpenses();  // Refresh the list after creation
    } catch (error) {
      print('Error creating expense: $error');
    }
  }

  /// Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      await supabase
          .from('expenses')
          .update(expense.toJson())
          .eq('id', expense.id);

      await fetchExpenses();  // Refresh the list after update
    } catch (error) {
      print('Error updating expense: $error');
    }
  }

  /// Delete an expense by ID
  Future<void> deleteExpense(int id) async {
    try {
      await supabase.from('expenses').delete().eq('id', id);
      _expenses.removeWhere((expense) => expense.id == id);
      notifyListeners();
    } catch (error) {
      print('Error deleting expense: $error');
    }
  }

  /// Clear all expenses (optional helper)
  void clearExpenses() {
    _expenses = [];
    notifyListeners();
  }
}
