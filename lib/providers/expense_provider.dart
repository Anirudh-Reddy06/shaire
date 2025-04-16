import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/expense.dart';
import '../services/logger_service.dart';

class ExpenseProvider with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Expense> _expenses = [];
  bool _isLoading = false;
  int _lastInsertedId = 0; // Changed from final to allow modification

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  int get lastInsertedId => _lastInsertedId;

  /// Fetch all expenses for the current user
  Future<void> fetchExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        LoggerService.error('Cannot fetch expenses: No user is logged in');
        return;
      }

      LoggerService.info('Fetching expenses for user: ${user.id}');

      final response = await supabase
          .from('expenses')
          .select('*')
          .eq('created_by', user.id)
          .order('date', ascending: false);

      LoggerService.debug('Fetched ${response.length} expenses');

      _expenses =
          response.map<Expense>((json) => Expense.fromJson(json)).toList();
    } catch (error) {
      LoggerService.error('Error fetching expenses', error);
      _expenses = []; // Reset to empty list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch expenses by group ID
  Future<List<Expense>> fetchGroupExpenses(int groupId) async {
    try {
      LoggerService.info('Fetching expenses for group: $groupId');

      final response = await supabase
          .from('expenses')
          .select('*')
          .eq('group_id', groupId)
          .order('date', ascending: false);

      return response.map<Expense>((json) => Expense.fromJson(json)).toList();
    } catch (error) {
      LoggerService.error('Error fetching group expenses', error);
      return [];
    }
  }

  /// Fetch a single expense by ID
  Future<Expense?> fetchExpenseById(int id) async {
    try {
      LoggerService.info('Fetching expense by ID: $id');

      final response = await supabase
          .from('expenses')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        LoggerService.warning('Expense not found with ID: $id');
        return null;
      }

      return Expense.fromJson(response);
    } catch (error) {
      LoggerService.error('Error fetching expense by ID', error);
      return null;
    }
  }

  /// Create a new expense
  Future<bool> createExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create a copy of expense.toJson() without the id field
      final Map<String, dynamic> expenseData = Map.from(expense.toJson())
        ..remove('id');

      LoggerService.info('Creating expense: ${expense.description}');
      LoggerService.debug('Expense data: $expenseData');

      final response =
          await supabase.from('expenses').insert(expenseData).select().single();

      _lastInsertedId = response['id'];
      LoggerService.info('Expense created with ID: $_lastInsertedId');

      await fetchExpenses(); // Refresh the list after creation
      return true;
    } catch (error) {
      LoggerService.error('Error creating expense', error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing expense
  Future<bool> updateExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();

      LoggerService.info('Updating expense ID: ${expense.id}');

      await supabase
          .from('expenses')
          .update(expense.toJson())
          .eq('id', expense.id);

      LoggerService.info('Expense updated successfully');

      await fetchExpenses(); // Refresh the list after update
      return true;
    } catch (error) {
      LoggerService.error('Error updating expense', error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete an expense by ID
  Future<bool> deleteExpense(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      LoggerService.info('Deleting expense ID: $id');

      await supabase.from('expenses').delete().eq('id', id);

      _expenses.removeWhere((expense) => expense.id == id);
      LoggerService.info('Expense deleted successfully');

      return true;
    } catch (error) {
      LoggerService.error('Error deleting expense', error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all expenses (optional helper)
  void clearExpenses() {
    _expenses = [];
    notifyListeners();
  }
}
