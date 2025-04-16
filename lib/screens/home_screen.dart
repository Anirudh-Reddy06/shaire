import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaire/providers/expense_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/currency_provider.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = true;
  double _youGet = 0;
  double _youOwe = 0;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Fetch real data
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch balances
      final balancesResponse = await Supabase.instance.client
          .from('balances')
          .select('*')
          .or('from_user_id.eq.${user.id},to_user_id.eq.${user.id}');

      double getTotalAmount = 0;
      double oweTotalAmount = 0;

      for (var balance in balancesResponse) {
        if (balance['from_user_id'] == user.id) {
          // You owe to others
          oweTotalAmount += (balance['amount'] as num).toDouble();
        } else {
          // Others owe to you
          getTotalAmount += (balance['amount'] as num).toDouble();
        }
      }

      // Fetch recent activities (use expenses for now)
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      await expenseProvider.fetchExpenses();

      // Convert expenses to activity items
      final activities = <Map<String, dynamic>>[];
      final groupedExpenses = <String, List<Map<String, dynamic>>>{};

      for (var expense in expenseProvider.expenses.take(10)) {
        final date = _formatDateKey(expense.date);
        final activity = {
          'title': expense.description,
          'action': expense.createdBy == user.id ? 'You paid' : 'Someone paid',
          'amount': expense.totalAmount,
          'icon': _getCategoryIcon(expense.categoryName),
          'date': expense.date,
        };

        if (!groupedExpenses.containsKey(date)) {
          groupedExpenses[date] = [];
        }
        groupedExpenses[date]!.add(activity);
      }

      setState(() {
        _youGet = getTotalAmount;
        _youOwe = oweTotalAmount;
        _recentActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Drinks':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Utilities':
        return Icons.power;
      case 'Rent':
        return Icons.home;
      case 'Other':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildActivityList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator(
    BuildContext context,
    String label,
    double amount,
    Color iconColor,
    IconData icon,
  ) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Expanded(
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.8),
                    ),
              ),
              Text(
                currencyProvider.format(amount),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String action,
    double amount,
    IconData icon,
  ) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    action,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              currencyProvider.format(amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchData,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildBalanceSection(context),
                    const SizedBox(height: 24),
                    _buildRecentActivities(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final netBalance = _youGet - _youOwe;
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyProvider.format(netBalance),
                  style: theme.textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildBalanceIndicator(
                      context,
                      'You Get',
                      _youGet,
                      Colors.greenAccent,
                      Icons.arrow_upward,
                    ),
                    const SizedBox(width: 24),
                    _buildBalanceIndicator(
                      context,
                      'You Owe',
                      _youOwe,
                      Colors.redAccent,
                      Icons.arrow_downward,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList(BuildContext context) {
    // Use real activities grouped by date
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.expenses;

    // Group expenses by date
    final groupedActivities = <String, List<Map<String, dynamic>>>{};

    for (var expense in expenses.take(10)) {
      final dateKey = _formatDateKey(expense.date);

      if (!groupedActivities.containsKey(dateKey)) {
        groupedActivities[dateKey] = [];
      }

      final user = Supabase.instance.client.auth.currentUser;
      final isMyExpense = expense.createdBy == user?.id;

      groupedActivities[dateKey]!.add({
        'title': expense.description,
        'action': isMyExpense ? 'You paid' : 'Someone paid',
        'amount': expense.totalAmount,
        'icon': _getCategoryIcon(expense.categoryName),
      });
    }

    if (groupedActivities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No recent activities',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final sortedDates = groupedActivities.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        if (a == 'Yesterday') return -1;
        if (b == 'Yesterday') return 1;
        return b.compareTo(a); // Most recent first
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = groupedActivities[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Text(
                date,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            ...items.map((item) => _buildActivityItem(
                  context,
                  item['title'],
                  item['action'],
                  item['amount'],
                  item['icon'],
                )),
          ],
        );
      },
    );
  }
}
