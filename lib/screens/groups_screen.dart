import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
import '../providers/currency_provider.dart'; // Add this import

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 0; // Start with Friends tab
    _searchController.addListener(_updateSearchQuery);
    _tabController.addListener(_tabChanged);
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _tabChanged() {
    // Only update if the tab is actually changing
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabChanged);
    _tabController.dispose();
    _searchController.removeListener(_updateSearchQuery);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Create our own AppBar here instead of using the one from MainScreen
      // This will allow us to have different styling for this screen
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).colorScheme.primary, // Colored AppBar
        foregroundColor: Colors.white, // White text and icons
        automaticallyImplyLeading: false, // No back button
        title: const Text('Groups', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0, // No shadow
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Groups'),
          ],
          labelColor: Colors.white, // Active tab text color
          unselectedLabelColor: Colors.white70, // Inactive tab text color
          indicatorColor: Colors.white, // White indicator line
          indicatorWeight: 3,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _tabController.index == 0
                    ? 'Search friends...'
                    : 'Search groups...',
                prefixIcon: Icon(Icons.search,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                // Use theme-aware colors instead of hardcoded grey
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).cardColor.withOpacity(0.5)
                    : Colors.grey.shade200,
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black38,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildGroupsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    // Get currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    // Sample friend data
    final List<Map<String, dynamic>> friends = [
      {'name': 'Alex Johnson', 'get': 10.0, 'owe': 5.0},
      {'name': 'Bailey Smith', 'get': 25.0, 'owe': 0.0},
      {'name': 'Charlie Brown', 'get': 0.0, 'owe': 15.0},
      {'name': 'Dana White', 'get': 7.5, 'owe': 7.5},
      {'name': 'Evan Peters', 'get': 12.0, 'owe': 3.0},
    ];

    // Filter friends by search query
    final filteredFriends = friends
        .where((friend) => friend['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    return Stack(
      children: [
        // Friend list
        filteredFriends.isEmpty
            ? const Center(child: Text('No friends found'))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                itemCount: filteredFriends.length,
                itemBuilder: (context, index) {
                  final friend = filteredFriends[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(friend['name']),
                      subtitle: Text(
                        'You get ${currencyProvider.format(friend['get'])}, You owe ${currencyProvider.format(friend['owe'])}',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const FriendDetailsScreen()),
                        );
                      },
                    ),
                  );
                },
              ),

        // FAB positioned at bottom right
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              _showAddFriendDialog();
            },
            tooltip: 'Add Friend',
            elevation: 4,
            child: const Icon(Icons.person_add),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab() {
    // Sample group data
    final List<Map<String, dynamic>> groups = [
      {'name': 'Roommates', 'members': 3},
      {'name': 'Family Trip', 'members': 5},
      {'name': 'Office Lunch', 'members': 8},
      {'name': 'Weekend Getaway', 'members': 4},
      {'name': 'Book Club', 'members': 6},
    ];

    // Filter groups by search query
    final filteredGroups = groups
        .where((group) => group['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    return Stack(
      children: [
        // Group list
        filteredGroups.isEmpty
            ? const Center(child: Text('No groups found'))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Space for FABs
                itemCount: filteredGroups.length,
                itemBuilder: (context, index) {
                  final group = filteredGroups[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8),
                        child: const Icon(Icons.group, color: Colors.white),
                      ),
                      title: Text(group['name']),
                      subtitle: Text('Members: ${group['members']}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GroupDetailsScreen()),
                        );
                      },
                    ),
                  );
                },
              ),

        // FABs positioned at bottom
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Join group button
              FloatingActionButton.small(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                onPressed: () {
                  _showJoinGroupDialog();
                },
                tooltip: 'Join Group',
                elevation: 4,
                child: const Icon(Icons.group_add),
              ),
              const SizedBox(height: 16),
              // Create group button
              FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                onPressed: () {
                  _showCreateGroupDialog();
                },
                tooltip: 'Create Group',
                elevation: 4,
                child: const Icon(Icons.create),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Dialog methods
  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Friend\'s Email or Username',
            hintText: 'Enter email or username',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Friend request sent')),
              );
            },
            child: const Text('SEND REQUEST'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Group'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Group Code',
            hintText: 'Enter group invite code',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Joining group...')),
              );
            },
            child: const Text('JOIN'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Group Name',
            hintText: 'Enter a name for your group',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group created')),
              );
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
}

class FriendDetailsScreen extends StatelessWidget {
  const FriendDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Details'),
      ),
      body: Column(
        children: [
          _buildGetOweStatus(),
          Expanded(
            child: ListView(
              children: [
                _buildTransactionItem('Dinner', 'You paid', 20.00),
                _buildTransactionItem('Movie', 'Friend paid', 15.00),
                _buildTransactionItem('Groceries', 'You paid', 30.00),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetOweStatus() {
    return Builder(builder: (context) {
      // Access the currency provider
      final currencyProvider = Provider.of<CurrencyProvider>(context);

      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusCard(context, 'You Get', 10.00, Colors.green),
            _buildStatusCard(context, 'You Owe', 5.00, Colors.red),
          ],
        ),
      );
    });
  }

  Widget _buildStatusCard(
      BuildContext context, String title, double amount, Color color) {
    // Access the currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(currencyProvider.format(amount), // Use format method
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String action, double amount) {
    return Builder(builder: (context) {
      // Access the currency provider
      final currencyProvider = Provider.of<CurrencyProvider>(context);

      return ListTile(
        title: Text(title),
        subtitle: Text(action),
        trailing: Text(currencyProvider.format(amount), // Use format method
            style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    });
  }
}

class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
      ),
      body: Column(
        children: [
          _buildGroupMembers(),
          Expanded(
            child: ListView(
              children: [
                _buildTransactionItem(
                    context, 'Dinner', 'Group expense', 50.00),
                _buildTransactionItem(context, 'Movie', 'Group expense', 30.00),
                _buildTransactionItem(
                    context, 'Groceries', 'Group expense', 40.00),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMembers() {
    // No changes needed here
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
          // Existing code...
          ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, String title, String action, double amount) {
    // Get the currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return ListTile(
      title: Text(title),
      subtitle: Text(action),
      trailing: Text(currencyProvider.format(amount),
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
