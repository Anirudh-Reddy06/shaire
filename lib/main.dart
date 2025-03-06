import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shaire',
      theme: AppTheme.theme(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const HomeScreen(),
    const GroupsScreen(),
    const SizedBox(), // Placeholder for FAB navigation
    const ExpensesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Navigate to add expense screen
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Shaire'),
      ),
      body: _screens[_selectedIndex == 2
          ? 0
          : _selectedIndex], // Avoid showing empty screen for index 2
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        tooltip: 'Add Expense',
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 6.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 12.0, 
        child: Container(
          height: 60, 
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            children: [
              // Left side 
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.home,
                        color: _selectedIndex == 0
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => _onItemTapped(0),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.group,
                        color: _selectedIndex == 1
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => _onItemTapped(1),
                    ),
                  ],
                ),
              ),
              
              // Space for the FAB
              const SizedBox(width: 40),
              
              // Right side 
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.receipt_long,
                        color: _selectedIndex == 3
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => _onItemTapped(3),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.person,
                        color: _selectedIndex == 4
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => _onItemTapped(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
