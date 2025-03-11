import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // Dummy data - this would come from a backend in a real app
  final List<double> _weeklyExpenses = [2340, 1850, 3200, 2780, 2420, 0, 0];
  final List<String> _weekLabels = [
    '4w ago',
    '3w ago',
    '2w ago',
    'Last week',
    'This week',
    'Next week',
    'In 2 weeks'
  ];

  // Expense change percentage
  final double _expenseChangePercent =
      -12.9; // Negative means spending decreased

  // Current week index (for highlighting)
  final int _currentWeekIndex = 4; // "This week" in our labels array

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly expense change card
              _buildExpenseChangeSummary(context, currencyProvider),

              const SizedBox(height: 24),

              // Weekly expenses graph
              _buildExpensesGraph(context, currencyProvider),

              const SizedBox(height: 24),

              // AI Insights
              _buildAIInsights(context),

              const SizedBox(height: 24),

              // Recent expenses
              _buildRecentExpenses(context, currencyProvider),

              const SizedBox(height: 24),

              // Category breakdown
              _buildCategoryBreakdown(context, currencyProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseChangeSummary(
      BuildContext context, CurrencyProvider currencyProvider) {
    final bool isSpendingDown = _expenseChangePercent < 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon indicating up or down
            Container(
              decoration: BoxDecoration(
                color: isSpendingDown
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                isSpendingDown ? Icons.trending_down : Icons.trending_up,
                color: isSpendingDown ? Colors.green : Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSpendingDown
                        ? 'Your expenses are down'
                        : 'Your expenses are up',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: 'You\'ve spent '),
                        TextSpan(
                          text:
                              '${isSpendingDown ? '' : '+'}${_expenseChangePercent.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSpendingDown ? Colors.green : Colors.red,
                          ),
                        ),
                        const TextSpan(text: ' compared to last week'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesGraph(
      BuildContext context, CurrencyProvider currencyProvider) {
    final double maxExpense =
        _weeklyExpenses.reduce((max, value) => math.max(max, value));
    // Projected expenses (slightly randomized based on average)
    final double avgExpense =
        (_weeklyExpenses.take(5).reduce((a, b) => a + b) / 5);
    final double nextWeekProjected =
        avgExpense * (0.95 + (math.Random().nextDouble() * 0.2));
    final double weekAfterProjected =
        avgExpense * (0.90 + (math.Random().nextDouble() * 0.3));

    // Create full list including projections
    final allExpenses = [..._weeklyExpenses];
    allExpenses[5] = nextWeekProjected; // Next week projection
    allExpenses[6] = weekAfterProjected; // Week after projection

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Expenses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Past spending and future projections',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            // Chart
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxExpense * 1.2, // Add some space at the top
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            _weekLabels[value.toInt()],
                            style: TextStyle(
                              fontSize: 10,
                              color: value.toInt() == _currentWeekIndex
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(
                    _weekLabels.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: allExpenses[index],
                          width: 20,
                          color: _getBarColor(context, index),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, Theme.of(context).colorScheme.primary,
                    'Past expenses'),
                const SizedBox(width: 24),
                _buildLegendItem(
                    context,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    'Current week'),
                const SizedBox(width: 24),
                _buildLegendItem(context, Colors.grey.shade400, 'Projected'),
              ],
            ),

            const SizedBox(height: 16),

            // Average spending
            Center(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Average weekly spending: '),
                    TextSpan(
                      text: currencyProvider.format(avgExpense),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBarColor(BuildContext context, int index) {
    // Current week (highlighted)
    if (index == _currentWeekIndex) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.8);
    }
    // Past weeks
    else if (index < _currentWeekIndex) {
      return Theme.of(context).colorScheme.primary;
    }
    // Future projections
    else {
      return Colors.grey.shade400;
    }
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAIInsights(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightTile(
              context,
              Icons.restaurant,
              'Food spending is 25% higher than usual this month.',
              'Consider meal planning to reduce food expenses.',
            ),
            const Divider(),
            _buildInsightTile(
              context,
              Icons.trending_down,
              'Transportation costs are down by 15%.',
              'Great work on reducing your commuting expenses!',
            ),
            const Divider(),
            _buildInsightTile(
              context,
              Icons.savings,
              'You could save ₹3,500 by reducing entertainment expenses.',
              'Try free local events or at-home activities.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(BuildContext context, IconData icon, String insight,
      String recommendation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses(
      BuildContext context, CurrencyProvider currencyProvider) {
    // Dummy recent expenses data
    final recentExpenses = [
      {
        'description': 'Restaurant bill',
        'date': 'Today',
        'amount': 1450.0,
        'category': 'Food & Drinks',
        'icon': Icons.restaurant
      },
      {
        'description': 'Movie tickets',
        'date': 'Yesterday',
        'amount': 500.0,
        'category': 'Entertainment',
        'icon': Icons.movie
      },
      {
        'description': 'Uber ride',
        'date': '3 days ago',
        'amount': 350.0,
        'category': 'Transportation',
        'icon': Icons.directions_car
      },
      {
        'description': 'Grocery shopping',
        'date': '5 days ago',
        'amount': 1870.0,
        'category': 'Shopping',
        'icon': Icons.shopping_cart
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Show all expenses
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentExpenses.map((expense) => _buildExpenseItem(
                  context,
                  currencyProvider,
                  expense['description'] as String,
                  expense['date'] as String,
                  expense['amount'] as double,
                  expense['category'] as String,
                  expense['icon'] as IconData,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(
      BuildContext context,
      CurrencyProvider currencyProvider,
      String description,
      String date,
      double amount,
      String category,
      IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$date · $category',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            currencyProvider.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, CurrencyProvider currencyProvider) {
    // Dummy category data
    final categories = [
      {
        'name': 'Food & Drinks',
        'amount': 5240.0,
        'percent': 32,
        'icon': Icons.restaurant
      },
      {
        'name': 'Transportation',
        'amount': 2150.0,
        'percent': 13,
        'icon': Icons.directions_car
      },
      {
        'name': 'Entertainment',
        'amount': 3420.0,
        'percent': 21,
        'icon': Icons.movie
      },
      {
        'name': 'Shopping',
        'amount': 4100.0,
        'percent': 25,
        'icon': Icons.shopping_bag
      },
      {
        'name': 'Others',
        'amount': 1470.0,
        'percent': 9,
        'icon': Icons.more_horiz
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...categories.map((category) => _buildCategoryItem(
                  context,
                  currencyProvider,
                  category['name'] as String,
                  category['amount'] as double,
                  category['percent'] as int,
                  category['icon'] as IconData,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
      BuildContext context,
      CurrencyProvider currencyProvider,
      String name,
      double amount,
      int percent,
      IconData icon) {
    final List<Color> colors = [
      Colors.blue.shade200,
      Colors.blue.shade300,
      Colors.blue.shade400,
      Colors.blue.shade500,
      Colors.blue.shade600,
    ];

    final colorIndex = math.min(
        (categories.length * percent / 100).round(), colors.length - 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name),
                    Text(currencyProvider.format(amount)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.7 + (0.3 * percent / 100)),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper variables
  List<Map<String, dynamic>> get categories => [
        {
          'name': 'Food & Drinks',
          'amount': 5240.0,
          'percent': 32,
          'icon': Icons.restaurant
        },
        {
          'name': 'Transportation',
          'amount': 2150.0,
          'percent': 13,
          'icon': Icons.directions_car
        },
        {
          'name': 'Entertainment',
          'amount': 3420.0,
          'percent': 21,
          'icon': Icons.movie
        },
        {
          'name': 'Shopping',
          'amount': 4100.0,
          'percent': 25,
          'icon': Icons.shopping_bag
        },
        {
          'name': 'Others',
          'amount': 1470.0,
          'percent': 9,
          'icon': Icons.more_horiz
        },
      ];
}
