import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/bill_service.dart';

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

  // Loading state
  bool _isLoading = false;
  final BillService _billService = BillService();

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
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.people_alt),
                              tooltip: 'Batch assignment',
                              onPressed: _billEntries.isNotEmpty ? _showBatchAssignmentOptions : null,
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
        SnackBar(content: Text('Error accessing camera or gallery: $e')),
      );
    }
  }

  Future<void> _getImageAndProcess(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // Check server health first
      //final bool isServerHealthy = await _billService.checkServerHealth();
      //if (!isServerHealthy) {
      //  ScaffoldMessenger.of(context).showSnackBar(
      //    const SnackBar(content: Text('Receipt scanning server is not available')),
      //  );
      //  return;
      //}
      
      // Pick an image
      final XFile? pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile == null) {
        // User canceled image picking
        return;
      }
      
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      // Process image
      File imageFile = File(pickedFile.path);
      Map<String, dynamic> result = await _billService.extractBillInfo(imageFile);
      
      // Hide loading indicator
      setState(() {
        _isLoading = false;
        // Switch to manual mode to show the entries
        _manualEntryMode = true;
      });
      
      // Process bill items from the result
      if (result.containsKey('items') && result['items'] is List) {
        List<dynamic> items = result['items'];
        
        // Clear existing bill entries if there are any
        _billEntries.clear();
        
        // Populate description field if available
        if (result.containsKey('merchant_name') && result['merchant_name'] != null) {
          _descriptionController.text = result['merchant_name'];
        }
        
        // Populate date field if available
        if (result.containsKey('date') && result['date'] != null) {
          try {
            _selectedDate = DateTime.parse(result['date']);
          } catch (e) {
            // If date parsing fails, keep the current date
          }
        }
        
        // Populate total amount if available
        if (result.containsKey('total_amount') && result['total_amount'] != null) {
          _totalAmountController.text = result['total_amount'].toString();
        }
        
        // Add bill entries from items
        for (var item in items) {
          if (item.containsKey('description') && item.containsKey('amount')) {
            final newEntry = BillEntry(
              description: item['description'],
              amount: double.tryParse(item['amount'].toString()) ?? 0.0,
              assignedTo: [], // Start with empty list instead of auto-assigning
            );
            
            setState(() {
              _billEntries.add(newEntry);
            });
          }
        }

        // After processing all items, show a message about assignment
        if (_billEntries.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt processed! Please assign people to each item.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Try to guess category based on merchant name or items
        _guessCategory();
        
      } else {
        // Show error if no items were found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not extract items from receipt')),
        );
      }
    } catch (e) {
      // Hide loading indicator and show error
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing receipt: $e')),
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

  void _editBillEntry(int index) {
    final entry = _billEntries[index];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddBillEntryBottomSheet(
        availableFriends: _availableFriends,
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

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save expense to database or state management
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved!')),
      );
      Navigator.pop(context);
    }
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
  _AddBillEntryBottomSheetState createState() => _AddBillEntryBottomSheetState();
}

class _AddBillEntryBottomSheetState extends State<_AddBillEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  List<String> _selectedFriends = [];

  @override
  void initState() {
    super.initState();
    
    // Pre-populate form if editing an existing entry
    if (widget.initialEntry != null) {
      _descriptionController.text = widget.initialEntry!.description;
      _amountController.text = widget.initialEntry!.amount.toString();
      _selectedFriends = List.from(widget.initialEntry!.assignedTo);
    }
  }

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
              widget.title, // Use the customized title
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