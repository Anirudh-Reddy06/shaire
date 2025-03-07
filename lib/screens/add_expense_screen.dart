import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Selected friends/group
  final List<String> _availableFriends = ['Alex', 'Bailey', 'Charlie', 'Dana', 'Evan'];
  final List<String> _selectedFriends = [];

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

  @override
  void dispose() {
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
                  icon: const Icon(Icons.document_scanner, color: Colors.white),
                  label: const Text('Scan Receipt'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                        ElevatedButton.icon(
                          onPressed: _addBillEntry,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _availableFriends.map((friend) {
        final isSelected = _selectedFriends.contains(friend);
        return FilterChip(
          label: Text(friend),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFriends.add(friend);
              } else {
                _selectedFriends.remove(friend);
              }
            });
          },
          avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
        );
      }).toList(),
    );
  }

  List<Widget> _buildBillEntries() {
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

    return _billEntries.asMap().entries.map((entry) {
      final index = entry.key;
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
                    '\$${billEntry.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
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

  void _scanReceipt() {
    // TODO: Implement receipt scanning functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt scanning not implemented yet')),
    );
  }

  void _addBillEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddBillEntryBottomSheet(
        availableFriends: _selectedFriends.isEmpty ? _availableFriends : _selectedFriends,
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

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save expense to database or state management
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved!')),
      );
      Navigator.pop(context);
    }
  }
}

// Bottom sheet for adding a bill entry
class _AddBillEntryBottomSheet extends StatefulWidget {
  final List<String> availableFriends;
  final Function(BillEntry) onAdd;

  const _AddBillEntryBottomSheet({
    required this.availableFriends,
    required this.onAdd,
  });

  @override
  _AddBillEntryBottomSheetState createState() => _AddBillEntryBottomSheetState();
}

class _AddBillEntryBottomSheetState extends State<_AddBillEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final List<String> _selectedFriends = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Bill Item',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
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
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                final isSelected = _selectedFriends.contains(friend);
                return FilterChip(
                  label: Text(friend),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFriends.add(friend);
                      } else {
                        _selectedFriends.remove(friend);
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
                  if (_formKey.currentState!.validate()) {
                    if (_selectedFriends.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please assign this item to at least one person')),
                      );
                      return;
                    }
                    
                    final newEntry = BillEntry(
                      description: _descriptionController.text,
                      amount: double.parse(_amountController.text),
                      assignedTo: List.from(_selectedFriends),
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
                child: const Text('Add Item'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Model class for bill entries
class BillEntry {
  final String description;
  final double amount;
  final List<String> assignedTo;

  BillEntry({
    required this.description,
    required this.amount,
    required this.assignedTo,
  });
}