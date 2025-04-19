import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shaire/database/expense.dart';
import 'package:shaire/providers/expense_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/bill_service.dart';
import '../services/logger_service.dart';
import '../providers/currency_provider.dart';
import '../database/receipt.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddExpenseScreen extends StatefulWidget {
  final int? groupId;
  final String? groupName;
  final dynamic friendId;
  final String? friendName;

  const AddExpenseScreen({
    super.key,
    this.groupId,
    this.groupName,
    this.friendId,
    this.friendName,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  var _availableFriends = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _selectedFriendData = [];
  final List<String> _selectedFriends = [];
  var _recentContactsAndGroups = <Map<String, dynamic>>[];
  final _supabase = Supabase.instance.client;

  // Form fields
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  final TextEditingController _totalAmountController = TextEditingController();

  // Manual entry mode
  bool _manualEntryMode = false;

  // Available categories
  final List<String> _categories = [
    'Food & Drinks',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Rent',
    'Other'
  ];

  // Bill entries
  final List<BillEntry> _billEntries = [];

  // Loading state
  bool _isLoading = false;
  final BillService _billService = BillService();

  // Add these variables to _AddExpenseScreenState class
  final TextEditingController _friendSearchController = TextEditingController();
  String _friendSearchQuery = '';

  // Add this property to your class
  final ReceiptService _receiptService = ReceiptService();
  int? _currentReceiptId;

  @override
  void initState() {
    super.initState();
    _friendSearchController.addListener(_updateFriendSearchQuery);

    _loadFriendsAndGroups();

    // Pre-fill group info if provided
    if (widget.groupName != null) {
      // Add the group to selected contacts
      _selectedFriends.add(widget.groupName!);

      // If you have a list of recent groups, you could update it
      final existingGroupIndex = _recentContactsAndGroups
          .indexWhere((g) => g['name'] == widget.groupName && g['isGroup']);

      if (existingGroupIndex < 0) {
        // Add to recent contacts if not already there
        _recentContactsAndGroups
            .insert(0, {'name': widget.groupName!, 'isGroup': true});
      }
    }

    // Pre-fill friend info if provided
    if (widget.friendName != null) {
      // Add the friend to selected contacts
      _selectedFriends.add(widget.friendName!);

      // Add to recent contacts if not already there
      final existingFriendIndex = _recentContactsAndGroups
          .indexWhere((g) => g['name'] == widget.friendName && !g['isGroup']);

      if (existingFriendIndex < 0) {
        _recentContactsAndGroups
            .insert(0, {'name': widget.friendName!, 'isGroup': false});
      }
    }
  }

  Future<void> _loadFriendsAndGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Load friends
      final friendsData = await _supabase
          .rpc('get_user_friends', params: {'p_user_id': userId});

      // Debug
      print('Friends data returned: ${friendsData.length} items');
      if (friendsData.isNotEmpty) {
        print('First friend example: ${friendsData.first}');
      }

      // Load groups
      final groupsData = await _supabase
          .from('group_members')
          .select('group_id, groups:group_id(id, name)')
          .eq('user_id', userId);

      print('Groups data returned: ${groupsData.length} items');

      // Format the data
      List<Map<String, dynamic>> friends = [];
      for (final f in friendsData) {
        friends.add({
          'id': f['user_id'],
          'name': f['full_name'] ?? f['username'] ?? 'Unknown',
          'username': f['username'],
          'avatar_url': f['avatar_url'],
          'isGroup': false,
        });
      }

      List<Map<String, dynamic>> groups = [];
      for (final g in groupsData) {
        final group = g['groups'] as Map<String, dynamic>;
        groups.add({
          'id': group['id'],
          'name': group['name'],
          'isGroup': true,
        });
      }

      // Combine friends and groups into available contacts
      final allContacts = [...friends, ...groups];
      final recentContacts = allContacts.take(5).toList();

      setState(() {
        _availableFriends = allContacts; // Changed: Use combined list here
        _recentContactsAndGroups = recentContacts;
      });

      print('Total available contacts loaded: ${_availableFriends.length}');
    } catch (e) {
      print('Error loading friends and groups: $e');
      // Add user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load contacts: $e')),
        );
      }
    }
  }

  void _updateFriendSearchQuery() {
    setState(() {
      _friendSearchQuery = _friendSearchController.text;
    });
  }

  @override
  void dispose() {
    _friendSearchController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Expense',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          if (_manualEntryMode)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveExpense,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group/Friends Selection
            Text(
              'Select Group or Friends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildFriendsSelection(),
            const SizedBox(height: 24),

            // Scan Receipt Button
            if (!_manualEntryMode) ...[
              Center(
                child: ElevatedButton.icon(
                  onPressed: _scanReceipt,
                  icon: Icon(Icons.document_scanner),
                  label: const Text('Scan Receipt'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _manualEntryMode = true;
                    });
                  },
                  child: const Text('Add Manually Instead'),
                ),
              ),
            ],

            // Loading Indicator
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Processing receipt...'),
                  ],
                ),
              ),
            ],

            // Manual Entry Form
            if (_manualEntryMode) ...[
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Total Amount
                    TextFormField(
                      controller: _totalAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the total amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bill Entries
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bill Entries',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.people_alt),
                              tooltip: 'Batch assignment',
                              onPressed: _billEntries.isNotEmpty
                                  ? _showBatchAssignmentOptions
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _addBillEntry,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List of bill entries
                    ..._buildBillEntries(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _friendSearchController,
          decoration: InputDecoration(
            hintText: 'Search friends or groups',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardColor.withOpacity(0.5)
                : Colors.grey.shade200,
          ),
        ),

        // Recent contacts/groups section
        if (_friendSearchQuery.isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Recent',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _recentContactsAndGroups.isEmpty
              ? const Text('No recent contacts')
              : SizedBox(
                  height: 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentContactsAndGroups.length,
                    itemBuilder: (context, index) {
                      final contact = _recentContactsAndGroups[index];
                      final isSelected =
                          _selectedFriends.contains(contact['name']);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedFriends.remove(contact['name']);
                                _selectedFriendData.removeWhere((f) =>
                                    f['id'] == contact['id'] &&
                                    f['isGroup'] == contact['isGroup']);
                              } else {
                                _selectedFriends.add(contact['name']);
                                _selectedFriendData.add({
                                  'id': contact['id'],
                                  'name': contact['name'],
                                  'isGroup': contact['isGroup'],
                                });
                              }
                            });
                          },
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              child: Icon(
                                contact['isGroup'] ? Icons.group : Icons.person,
                                size: 16,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                            label: Text(contact['name']),
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surface,
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],

        const SizedBox(height: 16),
        Text(
          'Friends & Groups',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),

        // Filtered friends and groups
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _availableFriends
              .where((friend) =>
                  _friendSearchQuery.isEmpty ||
                  friend['name']
                      .toLowerCase()
                      .contains(_friendSearchQuery.toLowerCase()))
              .map((friend) {
            final isSelected = _selectedFriends.contains(friend['name']);
            return FilterChip(
              label: Text(friend['name']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFriends.add(friend['name']);
                    _selectedFriendData.add({
                      'id': friend['id'],
                      'name': friend['name'],
                      'isGroup': friend['isGroup'],
                    });
                  } else {
                    _selectedFriends.remove(friend['name']);
                    _selectedFriendData.removeWhere((f) =>
                        f['id'] == friend['id'] &&
                        f['isGroup'] == friend['isGroup']);
                  }
                });
              },
              avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  // Update the _buildBillEntries method to group by type
  List<Widget> _buildBillEntries() {
    // Add currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    if (_billEntries.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('No bill entries yet. Add your first item!'),
          ),
        ),
      ];
    }

    // Group entries by type
    final itemEntries =
        _billEntries.where((e) => e.type == BillEntryType.item).toList();
    final taxEntries =
        _billEntries.where((e) => e.type == BillEntryType.tax).toList();
    final discountEntries =
        _billEntries.where((e) => e.type == BillEntryType.discount).toList();

    // Combined widgets list
    List<Widget> widgets = [];

    // Items section
    if (itemEntries.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: Text('Items', style: Theme.of(context).textTheme.titleMedium),
      ));
      widgets.addAll(_buildEntriesByType(itemEntries, currencyProvider));
    }

    // Tax section
    if (taxEntries.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
        child: Text('Tax', style: Theme.of(context).textTheme.titleMedium),
      ));
      widgets.addAll(_buildEntriesByType(taxEntries, currencyProvider));
    }

    // Discount section
    if (discountEntries.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
        child:
            Text('Discounts', style: Theme.of(context).textTheme.titleMedium),
      ));
      widgets.addAll(_buildEntriesByType(discountEntries, currencyProvider));
    }

    return widgets;
  }

  // Helper method to build entries of a specific type
  List<Widget> _buildEntriesByType(
      List<BillEntry> entries, CurrencyProvider currencyProvider) {
    return entries.asMap().entries.map((entry) {
      final index = _billEntries
          .indexOf(entry.value); // Get the index in the original list
      final billEntry = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      billEntry.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    currencyProvider.format(billEntry.amount),
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.titleMedium?.fontSize,
                      fontWeight: FontWeight.bold,
                      color: billEntry.type == BillEntryType.discount
                          ? Colors.green
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editBillEntry(index),
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeBillEntry(index),
                    color: Colors.red,
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Assigned to: ${billEntry.assignedTo.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _scanReceipt() async {
    final ImagePicker picker = ImagePicker();

    try {
      // Show options dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: const Text('Camera'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImageAndProcess(ImageSource.camera);
                    },
                  ),
                  const Padding(padding: EdgeInsets.all(8.0)),
                  GestureDetector(
                    child: const Text('Gallery'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImageAndProcess(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error accessing camera or gallery: $e'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _getImageAndProcess(ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      // Show loading indicator
      setState(() => _isLoading = true);

      // Use the original file
      final file = File(pickedFile.path);

      // Process the image with OCR
      Map<String, dynamic> billResult = {};
      Receipt? receipt;

      try {
        // First, upload the receipt to create a record
        receipt = await _receiptService.uploadReceipt(file);
        if (receipt != null) {
          _currentReceiptId = receipt.id;
        }

        // Then try OCR processing
        billResult = await _billService.extractBillInfo(file);
      } catch (e) {
        print('OCR extraction failed: $e');
        billResult = {}; // Empty result if OCR fails
      }

      // Hide loading indicator and update UI
      setState(() {
        _isLoading = false;
        _manualEntryMode = true; // Show the BillEntries UI
      });

      // Process billResult to populate the form if OCR was successful
      if (billResult.containsKey('items') && billResult['items'] is List) {
        final items = billResult['items'] as List;

        // Clear existing entries before adding new ones
        _billEntries.clear();

        // Add each item from the OCR result
        for (final item in items) {
          if (item is Map &&
              item.containsKey('description') &&
              item.containsKey('price')) {
            _billEntries.add(
              BillEntry(
                description: item['description'].toString(),
                amount: double.tryParse(item['price'].toString()) ?? 0.0,
                assignedTo: [], // No assignments initially
                type: BillEntryType.item,
              ),
            );
          }
        }

        // Set total amount if available
        if (billResult.containsKey('total')) {
          _totalAmountController.text = billResult['total'].toString();
        }

        // Set description if available (often store name)
        if (billResult.containsKey('merchant')) {
          _descriptionController.text = billResult['merchant'].toString();
          _guessCategory(); // Guess category from description
        }

        // Refresh UI
        setState(() {});
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  void _guessCategory() {
    final String description = _descriptionController.text.toLowerCase();

    if (description.contains('restaurant') ||
        description.contains('café') ||
        description.contains('cafe') ||
        description.contains('bar') ||
        description.contains('grill')) {
      _selectedCategory = 'Food & Drinks';
    } else if (description.contains('taxi') ||
        description.contains('uber') ||
        description.contains('lyft') ||
        description.contains('transport')) {
      _selectedCategory = 'Transportation';
    } else if (description.contains('cinema') ||
        description.contains('movie') ||
        description.contains('theatre') ||
        description.contains('theater')) {
      _selectedCategory = 'Entertainment';
    } else if (description.contains('market') ||
        description.contains('shop') ||
        description.contains('store')) {
      _selectedCategory = 'Shopping';
    } else {
      // Default to Other if no match
      _selectedCategory = 'Other';
    }
  }

  void _addBillEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddBillEntryBottomSheet(
        availableFriends: _selectedFriends.isEmpty
            ? _availableFriends
                .map((friend) => friend['name'] as String)
                .toList()
            : _selectedFriends,
        onAdd: (entry) {
          setState(() {
            _billEntries.add(entry);
          });
        },
      ),
    );
  }

  void _removeBillEntry(int index) {
    setState(() {
      _billEntries.removeAt(index);
    });
  }

  void _editBillEntry(int index) {
    final entry = _billEntries[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddBillEntryBottomSheet(
        availableFriends: _availableFriends
            .map((friend) => friend['name'] as String)
            .toList(),
        onAdd: (updatedEntry) {
          setState(() {
            _billEntries[index] = updatedEntry;
          });
        },
        initialEntry: entry, // Pass the existing entry to pre-populate the form
        title: 'Edit Bill Item', // Change the title to indicate editing mode
      ),
    );
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        // Get the current user ID
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception('User not authenticated');

        try {
          await _ensureUserProfileExists(user.id);
        } catch (e) {
          throw Exception('Profile creation failed: $e');
        }

        // Convert the string category to an integer ID
        int? categoryId = _getCategoryId(_selectedCategory);

        // Create the expense with real data
        final now = DateTime.now();
        final newExpense = Expense(
          id: 0,
          description: _descriptionController.text,
          totalAmount: double.parse(_totalAmountController.text),
          currency: Provider.of<CurrencyProvider>(context, listen: false)
              .currencyCode,
          date: _selectedDate,
          createdBy: user.id,
          groupId: widget.groupId, // Keep this for group expenses
          categoryId: categoryId,
          receiptImageUrl: null,
          splitType: 'equal',
          createdAt: now,
          updatedAt: now,
        );

        // Save the expense using the provider
        final expenseProvider =
            Provider.of<ExpenseProvider>(context, listen: false);
        final success = await expenseProvider.createExpense(newExpense);

        if (success) {
          final expenseId = expenseProvider.lastInsertedId;

          // Handle participant relationships
          await _saveExpenseParticipants(expenseId);

          // If we have a receipt image, link it to the expense
          if (_currentReceiptId != null) {
            await _receiptService.linkReceiptToExpense(
                _currentReceiptId!, expenseId);
          }
        }

        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense saved successfully')),
          );
          Navigator.pop(context); // Return to previous screen
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving expense: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _saveExpenseParticipants(int expenseId) async {
    try {
      // Get the total amount
      final totalAmount = double.parse(_totalAmountController.text);
      final count = _selectedFriendData.length;

      if (count == 0) return;

      // Calculate even split
      final perPersonAmount = totalAmount / count;

      // Create participant records
      final participants = _selectedFriendData.map((friend) {
        final isGroup = friend['isGroup'] == true;

        return {
          'expense_id': expenseId,
          'user_id': isGroup ? null : friend['id'],
          'group_id': isGroup ? friend['id'] : null,
          'share_amount': perPersonAmount,
          'paid_amount': 0, // Adjust this based on who paid
          'status': 'pending',
        };
      }).toList();

      // Insert into expense_participants table
      await _supabase.from('expense_participants').insert(participants);
    } catch (e) {
      print('Error saving expense participants: $e');
      rethrow;
    }
  }

  Future<void> _ensureUserProfileExists(String userId) async {
    try {
      LoggerService.info('Checking if profile exists for user ID: $userId');

      // Check if profile exists
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        LoggerService.info('Profile not found, creating new profile');

        // Create a complete profile with all required fields
        final profileData = {
          'id': userId,
          'username': userId.substring(0, 8),
          'full_name': 'User',
          'updated_at': DateTime.now().toIso8601String(),
          'currency': 'INR',
          'avatar_url':
              null, // Explicitly include all columns that might be NOT NULL
          'website': null,
          'email': Supabase.instance.client.auth.currentUser?.email,
        };

        LoggerService.debug('Creating profile with data: $profileData');

        // Use explicit insert with returning
        final insertResponse =
            await Supabase.instance.client.from('profiles').insert(profileData);

        LoggerService.info('Profile created successfully');

        // Add a small delay and verify profile creation
        await Future.delayed(const Duration(milliseconds: 300));
        final verifyProfile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (verifyProfile == null) {
          LoggerService.error('Failed to verify profile creation');
          throw Exception('Failed to create user profile: verification failed');
        }

        LoggerService.info('Profile creation verified successfully');
      } else {
        LoggerService.info('Profile already exists for user: $userId');
      }
    } catch (e) {
      LoggerService.error('Error ensuring profile exists', e);
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Helper method to convert category names to IDs
  int? _getCategoryId(String? categoryName) {
    if (categoryName == null) return null;

    // Define your category mappings
    final Map<String, int> categoryMap = {
      'Food & Drinks': 1,
      'Transportation': 2,
      'Entertainment': 3,
      'Shopping': 4,
      'Utilities': 5,
      'Rent': 6,
      'Other': 7,
    };

    return categoryMap[categoryName] ??
        7; // Default to 'Other' (7) if not found
  }

  void _showBatchAssignmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batch Assign Items',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Assign all items to everyone'),
              onTap: () {
                for (int i = 0; i < _billEntries.length; i++) {
                  setState(() {
                    _billEntries[i] = BillEntry(
                      description: _billEntries[i].description,
                      amount: _billEntries[i].amount,
                      assignedTo: List.from(_availableFriends),
                    );
                  });
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Assign all items to selected friends'),
              enabled: _selectedFriends.isNotEmpty,
              onTap: () {
                if (_selectedFriends.isEmpty) return;

                for (int i = 0; i < _billEntries.length; i++) {
                  setState(() {
                    _billEntries[i] = BillEntry(
                      description: _billEntries[i].description,
                      amount: _billEntries[i].amount,
                      assignedTo: List.from(_selectedFriends),
                    );
                  });
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear all assignments'),
              onTap: () {
                for (int i = 0; i < _billEntries.length; i++) {
                  setState(() {
                    _billEntries[i] = BillEntry(
                      description: _billEntries[i].description,
                      amount: _billEntries[i].amount,
                      assignedTo: [],
                    );
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet for adding a bill entry
class _AddBillEntryBottomSheet extends StatefulWidget {
  final List<String> availableFriends;
  final Function(BillEntry) onAdd;
  final BillEntry? initialEntry; // Add this to support editing
  final String title; // Add this to customize the title

  const _AddBillEntryBottomSheet({
    required this.availableFriends,
    required this.onAdd,
    this.initialEntry,
    this.title = 'Add Bill Item',
  });

  @override
  _AddBillEntryBottomSheetState createState() =>
      _AddBillEntryBottomSheetState();
}

// Update the _AddBillEntryBottomSheetState class
class _AddBillEntryBottomSheetState extends State<_AddBillEntryBottomSheet> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  List<String> selectedFriends = [];
  BillEntryType selectedType = BillEntryType.item;

  @override
  void initState() {
    super.initState();

    // Pre-populate form if editing an existing entry
    if (widget.initialEntry != null) {
      descriptionController.text = widget.initialEntry!.description;
      amountController.text = widget.initialEntry!.amount.toString();
      selectedFriends = List.from(widget.initialEntry!.assignedTo);
      selectedType = widget.initialEntry!.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Item Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an item description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Entry type selector
            DropdownButtonFormField<BillEntryType>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Entry Type',
                border: OutlineInputBorder(),
              ),
              items: BillEntryType.values.map((type) {
                String label;
                switch (type) {
                  case BillEntryType.item:
                    label = 'Item';
                    break;
                  case BillEntryType.tax:
                    label = 'Tax';
                    break;
                  case BillEntryType.discount:
                    label = 'Discount';
                    break;
                }

                return DropdownMenuItem<BillEntryType>(
                  value: type,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixText: currencyProvider.currencySymbol,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Assign to:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.availableFriends.map((friend) {
                final isSelected = selectedFriends.contains(friend);
                return FilterChip(
                  label: Text(friend),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedFriends.add(friend);
                      } else {
                        selectedFriends.remove(friend);
                      }
                    });
                  },
                  avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    if (selectedFriends.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please assign this item to at least one person'),
                            behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }

                    final newEntry = BillEntry(
                      description: descriptionController.text,
                      amount: double.parse(amountController.text),
                      assignedTo: List.from(selectedFriends),
                      type: selectedType,
                    );

                    widget.onAdd(newEntry);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                    widget.initialEntry != null ? 'Update Item' : 'Add Item'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Add these at the bottom of the file, outside any class
enum BillEntryType { item, tax, discount }

class BillEntry {
  final String description;
  final double amount;
  final List<String> assignedTo;
  final BillEntryType type;

  BillEntry({
    required this.description,
    required this.amount,
    required this.assignedTo,
    this.type = BillEntryType.item,
  });
}
