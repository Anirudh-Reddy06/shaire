import 'package:flutter/material.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 0; // Start with Friends tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Friends'),
              Tab(text: 'Groups'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
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
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: 5, // Replace with actual friends list length
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text('Friend $index'),
                subtitle: Text('You get \$10.00, You owe \$5.00'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FriendDetailsScreen()),
                  );
                },
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            onPressed: () {
              // Add friend logic here
              print('Add friend button pressed');
            },
            child: Icon(Icons.person_add),
            tooltip: 'Add Friend',
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: 5, // Replace with actual groups list length
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.group),
                title: Text('Group $index'),
                subtitle: Text('Members: 5'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GroupDetailsScreen()),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  // Join group logic here
                  print('Join group button pressed');
                },
                child: Icon(Icons.group_add),
                tooltip: 'Join Group',
              ),
              FloatingActionButton(
                onPressed: () {
                  // Create group logic here
                  print('Create group button pressed');
                },
                child: Icon(Icons.create),
                tooltip: 'Create Group',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FriendDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Details'),
      ),
      body: Column(
        children: [
          _buildGetOweStatus(),
          Expanded(
            child: ListView(
              children: [
                _buildTransactionItem('Dinner', 'You paid', '\$20.00'),
                _buildTransactionItem('Movie', 'Friend paid', '\$15.00'),
                _buildTransactionItem('Groceries', 'You paid', '\$30.00'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetOweStatus() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusCard('You Get', '\$10.00', Colors.green),
          _buildStatusCard('You Owe', '\$5.00', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String amount, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(amount, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String action, String amount) {
    return ListTile(
      title: Text(title),
      subtitle: Text(action),
      trailing: Text(amount, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class GroupDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Details'),
      ),
      body: Column(
        children: [
          _buildGroupMembers(),
          Expanded(
            child: ListView(
              children: [
                _buildTransactionItem('Dinner', 'Group expense', '\$50.00'),
                _buildTransactionItem('Movie', 'Group expense', '\$30.00'),
                _buildTransactionItem('Groceries', 'Group expense', '\$40.00'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMembers() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Group Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(child: Icon(Icons.person)),
              SizedBox(width: 8),
              CircleAvatar(child: Icon(Icons.person)),
              SizedBox(width: 8),
              CircleAvatar(child: Icon(Icons.person)),
              SizedBox(width: 8),
              Text('5 members'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String action, String amount) {
    return ListTile(
      title: Text(title),
      subtitle: Text(action),
      trailing: Text(amount, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
