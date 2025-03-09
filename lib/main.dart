import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ikcvgwtrgbeorwdycrxs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrY3Znd3RyZ2Jlb3J3ZHljcnhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE1MTM3MDMsImV4cCI6MjA1NzA4OTcwM30.azV2oLxI813aNEfmrApta7h6PZ1sbo31NgQq4s6W2Eo',
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Shaire',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.themeMode,
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
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

  // Screen titles map (for centered title)
  final Map<int, String> _screenTitles = {
    0: 'Shaire',
    1: 'Groups',
    3: 'Expenses',
    4: 'Profile',
  };

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
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8, right: 8),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: Text(
          _screenTitles[_selectedIndex] ?? '',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        actions: [
          // Show notifications icon on home screen, settings icon on profile screen
          Padding(
            padding: const EdgeInsets.only(right: 16 ,top: 8, bottom: 8, left: 8),
            child: IconButton(
            icon: Icon(
              _selectedIndex == 0 ? Icons.notifications : 
              _selectedIndex == 4 ? Icons.settings : null,
            ),
            onPressed: () {
              if (_selectedIndex == 0) {
                // Navigate to notifications
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon')),
                );
              } else if (_selectedIndex == 4) {
                // Navigate to settings
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }
            },
            // Hide button if not on home or profile screen
            style: _selectedIndex != 0 && _selectedIndex != 4
                ? ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(Colors.transparent),
                  )
                : null,
          ),
          ),
        ],
      ),
      body: _screens[_selectedIndex == 2 ? 0 : _selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        tooltip: 'Add Expense',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 12.0,
        child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side items
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shaire button
                    _buildNavItem(0, Icons.home, 'Shaire'),
                    // Groups button
                    _buildNavItem(1, Icons.group, 'Groups'),
                  ],
                ),
              ),
              
              // Space for the FAB
              const SizedBox(width: 50),
              
              // Right side items
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Expenses button
                    _buildNavItem(3, Icons.receipt_long, 'Expenses'),
                    // Profile button
                    _buildNavItem(4, Icons.person, 'Profile'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build nav items with consistent style and reduced size
  Widget _buildNavItem(int index, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              icon,
              color: _selectedIndex == index
                  ? Theme.of(context).colorScheme.primary
                  : null,
              size: 28, // Explicit size
            ),
            onPressed: () => _onItemTapped(index),
            padding: EdgeInsets.zero, 
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: _selectedIndex == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
