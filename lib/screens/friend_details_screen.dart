import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'add_expense_screen.dart';

class FriendDetailsScreen extends StatefulWidget {
  final dynamic friendId;
  const FriendDetailsScreen({super.key, required this.friendId});

  @override
  State<FriendDetailsScreen> createState() => _FriendDetailsScreenState();
}

class _FriendDetailsScreenState extends State<FriendDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _loading = true, _error = false;
  String? _errorMsg;

  Map<String, dynamic>? _friendProfile;
  final List<Map<String, dynamic>> _expenses = [];
  double _youOwe = 0.0;
  double _youAreOwed = 0.0;
  double _netBalance = 0.0;

  late TabController _tabController;
  final _currencyFormatter = NumberFormat.currency(symbol: '₹');
  String? _currentUserId;
  late ExpenseProvider _expenseProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = _supabase.auth.currentUser?.id;
    _expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    _expenseProvider.addListener(_onExpensesChanged);
    _loadFriendDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expenseProvider.removeListener(_onExpensesChanged);
    super.dispose();
  }

  void _onExpensesChanged() {
    if (mounted) {
      _loadFriendDetails();
    }
  }

  Future<void> _loadFriendDetails() async {
  setState(() => _loading = true);
  try {
    // 1. Load friend's profile (unchanged)
    final profileRes = await _supabase
        .from('profiles')
        .select('full_name, username, avatar_url')
        .eq('id', widget.friendId)
        .single();

    _friendProfile = profileRes;

    // 2. Load expenses with fixed RPC function
    final expensesRes = await _supabase.rpc(
      'get_shared_expenses',
      params: {
        'p_current_user_id': _currentUserId,
        'p_friend_id': widget.friendId,
      },
    );

    _expenses.clear();
    _youOwe = 0;
    _youAreOwed = 0;

    for (final e in expensesRes) {
      final amount = e['total_amount'] as num;
      final yourShare = e['your_share'] as num? ?? 0;
      final friendShare = amount - yourShare; // Calculate friend's share
      final youPaid = e['you_paid'] as num? ?? 0;
      final friendPaid = e['friend_paid'] as num? ?? 0;

      // Fix balance calculation for each expense
      if (youPaid > yourShare) {
        // You paid more than your share, friend owes you
        _youAreOwed += (youPaid - yourShare);
      }
      
      if (friendPaid > friendShare) {
        // Friend paid more than their share, you owe them
        _youOwe += (friendPaid - friendShare);
      }

      _expenses.add({
        'id': e['id'] as int,
        'description': e['description'],
        'amount': amount,
        'date': DateTime.parse(e['date'] as String),
        'creator_name': e['creator_name'],
        'your_share': yourShare,
        'you_paid': youPaid,
        'friend_paid': friendPaid,
      });
    }

    _netBalance = _youAreOwed - _youOwe;
  } catch (e) {
    _error = true;
    _errorMsg = e.toString();
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}



  void _navigateToAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          friendId: widget.friendId,
          friendName:
              _friendProfile?['full_name'] ?? _friendProfile?['username'],
        ),
      ),
    ).then((_) => _loadFriendDetails());
  }

  Future<void> _settleUp() async {
    final selectedAmount = await showDialog<double>(
      context: context,
      builder: (ctx) => SettleUpDialog(
        youOwe: _youOwe,
        youAreOwed: _youAreOwed,
      ),
    );

    if (selectedAmount != null && selectedAmount > 0) {
      setState(() => _loading = true);
      try {
        // Create a payment record
        await _supabase.from('payments').insert({
          'from_user_id': _netBalance < 0 ? _currentUserId : widget.friendId,
          'to_user_id': _netBalance < 0 ? widget.friendId : _currentUserId,
          'amount': selectedAmount,
          'currency': 'USD',
          'payment_method': 'manual',
          'payment_date': DateTime.now().toIso8601String(),
          'status': 'completed',
          'notes': 'Settlement payment',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Settlement of ${_currencyFormatter.format(selectedAmount)} recorded')),
        );

        // Refresh data
        await _loadFriendDetails();
      } catch (e) {
        setState(() {
          _loading = false;
          _error = true;
          _errorMsg = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording payment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;

    if (_loading && _friendProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friend Details')),
        body: Center(child: Text('Error: $_errorMsg')),
      );
    }

    final friendName =
        _friendProfile?['full_name'] ?? _friendProfile?['username'] ?? 'Friend';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        iconTheme: IconThemeData(color: onPrimaryColor),
        titleTextStyle:
            theme.textTheme.titleLarge?.copyWith(color: onPrimaryColor),
        title: Text(friendName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: onPrimaryColor,
          dividerColor: onPrimaryColor,
          labelColor: onPrimaryColor,
          unselectedLabelColor: onPrimaryColor.withAlpha((0.7 * 255).round()),
          tabs: const [
            Tab(text: 'EXPENSES'),
            Tab(text: 'SUMMARY'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Balance summary card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _netBalance >= 0 ? 'You are owed' : 'You owe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        _currencyFormatter.format(_netBalance.abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _netBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (_netBalance != 0) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _settleUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: onPrimaryColor,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.handshake),
                          SizedBox(width: 8),
                          Text('Settle Up'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expenses list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Expenses Tab
                _expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No shared expenses yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _navigateToAddExpense,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: onPrimaryColor,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Add an expense'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFriendDetails,
                        child: ListView.builder(
                          itemCount: _expenses.length,
                          itemBuilder: (ctx, i) {
                            final exp = _expenses[i];
                            final amount = exp['amount'] as num;
                            final yourShare = exp['your_share'] as num;
                            final friendShare = amount - yourShare;
                            final youPaid = exp['you_paid'] as num;
                            final friendPaid = exp['friend_paid'] as num;
                            final date = exp['date'] as DateTime;

                            // Calculate what's owed on this specific expense
                            final friendOwesYou = youPaid > yourShare ? youPaid - yourShare : 0.0;
                            final youOweFriend = friendPaid > friendShare ? friendPaid - friendShare : 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: const Icon(Icons.receipt_long),
                                ),
                                title: Text(
                                  exp['description'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total: ${_currencyFormatter.format(amount)}'),
                                    const SizedBox(height: 2),
                                    if (friendOwesYou > 0)
                                      Text(
                                        '${_friendProfile?['full_name']} owes you ${_currencyFormatter.format(friendOwesYou)}',
                                        style: const TextStyle(color: Colors.green),
                                      )
                                    else if (youOweFriend > 0)
                                      Text(
                                        'You owe ${_currencyFormatter.format(youOweFriend)}',
                                        style: const TextStyle(color: Colors.red),
                                      )
                                    else
                                      const Text('Settled'),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        )
                      ),

                // Summary Tab - Payment history and other details
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expense Statistics',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                title: const Text('Total Shared Expenses'),
                                trailing: Text(
                                  '${_expenses.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              ListTile(
                                title: const Text('Total Amount'),
                                trailing: Text(
                                  _currencyFormatter.format(
                                      _expenses.fold<double>(
                                          0,
                                          (sum, exp) =>
                                              sum + (exp['amount'] as num))),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _navigateToAddExpense,
              backgroundColor: primaryColor,
              foregroundColor: onPrimaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// Dialog for settling up
class SettleUpDialog extends StatefulWidget {
  final double youOwe;
  final double youAreOwed;

  const SettleUpDialog({
    super.key,
    required this.youOwe,
    required this.youAreOwed,
  });

  @override
  State<SettleUpDialog> createState() => _SettleUpDialogState();
}

class _SettleUpDialogState extends State<SettleUpDialog> {
  late TextEditingController _amountController;
  final _formatter = NumberFormat.currency(symbol: '₹');
  bool _useFullAmount = true;

  @override
  void initState() {
    super.initState();
    final netAmount = (widget.youOwe - widget.youAreOwed).abs();
    _amountController =
        TextEditingController(text: netAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final netAmount = (widget.youOwe - widget.youAreOwed).abs();
    final youPay = widget.youOwe > widget.youAreOwed;

    return AlertDialog(
      title: Text(youPay ? 'You Pay' : 'They Pay'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Settle up with ${_formatter.format(netAmount)}?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Use full amount'),
            value: _useFullAmount,
            onChanged: (value) {
              setState(() {
                _useFullAmount = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (!_useFullAmount)
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              final amount = _useFullAmount
                  ? netAmount
                  : double.parse(_amountController.text);
              Navigator.pop(context, amount);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
            }
          },
          child: const Text('RECORD'),
        ),
      ],
    );
  }
}
