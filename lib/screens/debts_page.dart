import 'package:debt_app/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';
import '../providers/language_provider.dart';
import '../database/database_helper.dart';
import '../widgets/table_widget.dart';
import '../widgets/dialog_widget.dart';
import 'package:provider/provider.dart';

class _EditDebtDialog extends StatefulWidget {
  final String title;
  final String detailsLabel;
  final String nameLabel;
  final String phoneLabel;
  final String materialLabel;
  final String quantityLabel;
  final String priceLabel;
  final String currencyLabel;
  final String cancelText;
  final String saveText;
  final int? userId;
  final String? userName;
  final Map<String, dynamic>? initialDebt;
  final Function(Map<String, dynamic>) onSave;

  const _EditDebtDialog({
    required this.title,
    required this.detailsLabel,
    required this.nameLabel,
    required this.phoneLabel,
    required this.materialLabel,
    required this.quantityLabel,
    required this.priceLabel,
    required this.currencyLabel,
    required this.cancelText,
    required this.saveText,
    required this.userId,
    required this.userName,
    required this.initialDebt,
    required this.onSave,
  });

  @override
  State<_EditDebtDialog> createState() => _EditDebtDialogState();
}

class _EditDebtDialogState extends State<_EditDebtDialog> {
  late final TextEditingController _detailsController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _materialController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final GlobalKey<FormState> _formKey;
  bool _isOwed = true;
  int _selectedCurrencyId = 1;
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _users = [];
  int? _selectedUserId;
  bool _isNewUser = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController(
      text: widget.initialDebt?['details'] ?? '',
    );
    _nameController = TextEditingController(
      text: widget.initialDebt?['user_name'] ?? widget.userName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialDebt?['phone'] ?? '',
    );
    _materialController = TextEditingController(
      text: widget.initialDebt?['material'] ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.initialDebt?['quantity']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.initialDebt?['price']?.toString() ?? '',
    );
    _isOwed = widget.initialDebt?['is_owed'] == 1;
    _selectedCurrencyId = widget.initialDebt?['currency_id'] ?? 1;
    _formKey = GlobalKey<FormState>();
    _loadCurrencies();
    _loadUsers();
    _searchController = TextEditingController();
  }

  Future<void> _loadUsers() async {
    final dbHelper = DatabaseHelper();
    final users = await dbHelper.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        if (widget.userId != null) {
          _selectedUserId = widget.userId;
          _isNewUser = false;
        } else if (widget.initialDebt?['user_id'] != null) {
          _selectedUserId = widget.initialDebt?['user_id'];
          _isNewUser = false;
        }
      });
    }
  }

  Future<void> _loadCurrencies() async {
    final dbHelper = DatabaseHelper();
    final currencies = await dbHelper.getCurrencies();
    if (mounted) {
      setState(() {
        _currencies = currencies;
      });
    }
  }

  void _handleUserSelection(int? userId) {
    setState(() {
      _selectedUserId = userId;
      _isNewUser = userId == null;
      if (!_isNewUser) {
        final selectedUser = _users.firstWhere(
          (user) => user['id'] == userId,
          orElse: () => {'name': '', 'phone': ''},
        );
        _nameController.text = selectedUser['name'] ?? '';
        _phoneController.text = selectedUser['phone'] ?? '';
      } else {
        _nameController.text = '';
        _phoneController.text = '';
      }
    });
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _materialController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _detailsController,
                      decoration: InputDecoration(
                        labelText: widget.detailsLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (widget.userId == null &&
                        widget.initialDebt == null) ...[
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return _users
                              .map((user) => user['name'] as String)
                              .where(
                                (name) => name.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                ),
                              );
                        },
                        onSelected: (String selection) {
                          final selectedUser = _users.firstWhere(
                            (user) => user['name'] == selection,
                            orElse: () => {'id': null, 'name': '', 'phone': ''},
                          );
                          if (selectedUser['id'] != null) {
                            setState(() {
                              _isNewUser = false;
                              _selectedUserId = selectedUser['id'];
                              _nameController.text = selectedUser['name'] ?? '';
                              _phoneController.text =
                                  selectedUser['phone'] ?? '';
                            });
                          } else {
                            setState(() {
                              _isNewUser = true;
                              _selectedUserId = null;
                              _nameController.text = selection;
                              _phoneController.text = '';
                            });
                          }
                        },
                        fieldViewBuilder: (
                          BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: languageProvider.translate(
                                'users.name',
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon:
                                  _selectedUserId != null
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _isNewUser = true;
                                            _selectedUserId = null;
                                            textEditingController.clear();
                                            _nameController.text = '';
                                            _phoneController.text = '';
                                          });
                                        },
                                      )
                                      : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isNewUser = true;
                                _selectedUserId = null;
                                _nameController.text = value;
                                _phoneController.text = '';
                              });
                            },
                          );
                        },
                        optionsViewBuilder: (
                          BuildContext context,
                          AutocompleteOnSelected<String> onSelected,
                          Iterable<String> options,
                        ) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.3,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (
                                    BuildContext context,
                                    int index,
                                  ) {
                                    final String option = options.elementAt(
                                      index,
                                    );
                                    return ListTile(
                                      title: Text(option),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: _isNewUser,
                        decoration: InputDecoration(
                          labelText: widget.phoneLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                    ] else if (widget.initialDebt != null ||
                        widget.userId != null) ...[
                      Text(
                        '${widget.nameLabel}: ${widget.initialDebt?['user_name'] ?? widget.userName ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _materialController,
                      decoration: InputDecoration(
                        labelText: widget.materialLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: widget.quantityLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: widget.priceLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedCurrencyId,
                            decoration: InputDecoration(
                              labelText: widget.currencyLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items:
                                _currencies.map((currency) {
                                  return DropdownMenuItem<int>(
                                    value: currency['id'],
                                    child: Text(
                                      '${currency['code']} (${currency['symbol']})',
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrencyId = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                languageProvider.translate('debts.is_owed'),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isOwed,
                                onChanged: (value) {
                                  setState(() {
                                    _isOwed = value;
                                  });
                                },
                                activeColor: Colors.red,
                                inactiveThumbColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(widget.cancelText),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final debt = {
                          'details': _detailsController.text,
                          'name': _nameController.text,
                          'phone': _phoneController.text,
                          'material': _materialController.text,
                          'quantity': int.parse(_quantityController.text),
                          'price': int.parse(_priceController.text),
                          'is_owed': _isOwed ? 1 : 0,
                          'currency_id': _selectedCurrencyId,
                        };
                        widget.onSave(debt);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(widget.saveText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DebtsPage extends StatefulWidget {
  final int? userId;
  final String? userName;

  const DebtsPage({super.key, this.userId, this.userName});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final List<Map<String, dynamic>> _debts = [];
  late TextEditingController _detailsController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _materialController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isCardView = false;
  int _selectedCurrencyId = 1; // Default to SP
  List<Map<String, dynamic>> _currencies = [];
  int? _selectedSummaryCurrencyId; // For summary currency selection
  static const int ALL_CURRENCIES_ID = -1; // Special ID for "All" option
  Map<int, Map<String, double>>? _cachedCurrencyTotals;
  double? _cachedTotalOwedInSP;
  double? _cachedTotalOwingInSP;
  bool _isSummaryVisible = false; // New state variable for summary visibility

  @override
  void initState() {
    super.initState();
    _loadDebts();
    _loadCurrencies();
    _initializeControllers();
    _selectedSummaryCurrencyId =
        _selectedCurrencyId; // Initialize with default currency
  }

  void _initializeControllers() {
    _detailsController = TextEditingController();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _materialController = TextEditingController();
    _quantityController = TextEditingController();
    _priceController = TextEditingController();
  }

  void _disposeControllers() {
    _detailsController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _materialController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    try {
      final debts = await _dbHelper.getDebts();
      if (!mounted) return;

      setState(() {
        _debts.clear();
        if (widget.userId != null) {
          _debts.addAll(
            debts.where((debt) => debt['user_id'] == widget.userId),
          );
        } else {
          _debts.addAll(debts);
        }
        _invalidateCache();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading debts: $e')));
      }
    }
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await _dbHelper.getCurrencies();
      if (!mounted) return;

      setState(() {
        _currencies = currencies;
        if (!_currencies.any((c) => c['id'] == _selectedCurrencyId)) {
          _selectedCurrencyId = _currencies.first['id'];
        }
        if (_selectedSummaryCurrencyId != null &&
            !_currencies.any((c) => c['id'] == _selectedSummaryCurrencyId) &&
            _selectedSummaryCurrencyId != ALL_CURRENCIES_ID) {
          _selectedSummaryCurrencyId = _currencies.first['id'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading currencies: $e')));
      }
    }
  }

  void _showEditDialog([int? index]) async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final title = languageProvider.translate(
      index != null ? 'debts.edit_debt' : 'debts.add_debt',
    );
    final detailsLabel = languageProvider.translate('debts.details');
    final nameLabel = languageProvider.translate('debts.name');
    final phoneLabel = languageProvider.translate('users.phone');
    final materialLabel = languageProvider.translate('debts.material');
    final quantityLabel = languageProvider.translate('debts.quantity');
    final priceLabel = languageProvider.translate('debts.price');
    final currencyLabel = languageProvider.translate('debts.currency');
    final cancelText = languageProvider.translate('debts.cancel');
    final saveText = languageProvider.translate('debts.save_changes');

    Map<String, dynamic>? initialDebt;
    if (index != null) {
      initialDebt = _debts[index];
    } else if (widget.userId != null) {
      try {
        final user = await _dbHelper.getUserById(widget.userId!);
        if (user != null && mounted) {
          initialDebt = {
            'user_name': widget.userName ?? '',
            'phone': user['phone'] ?? '',
          };
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading user data: $e')),
          );
          return;
        }
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => _EditDebtDialog(
            title: title,
            detailsLabel: detailsLabel,
            nameLabel: nameLabel,
            phoneLabel: phoneLabel,
            materialLabel: materialLabel,
            quantityLabel: quantityLabel,
            priceLabel: priceLabel,
            currencyLabel: currencyLabel,
            cancelText: cancelText,
            saveText: saveText,
            userId: widget.userId,
            userName: widget.userName,
            initialDebt: initialDebt,
            onSave: (debt) async {
              try {
                int userId;
                if (widget.userId != null) {
                  userId = widget.userId!;
                  if (debt['phone'].isNotEmpty) {
                    await _dbHelper.updateUser(userId, {
                      'phone': debt['phone'],
                    });
                  }
                } else {
                  final users = await _dbHelper.getUsers();
                  final selectedUser = users.firstWhere(
                    (user) => user['name'] == debt['name'],
                    orElse: () => {'id': null},
                  );

                  if (selectedUser['id'] == null) {
                    userId = await _dbHelper.insertUser({
                      'name': debt['name'],
                      'phone': debt['phone'],
                    });
                  } else {
                    userId = selectedUser['id'];
                    if (selectedUser['phone'] != debt['phone']) {
                      await _dbHelper.updateUser(userId, {
                        'phone': debt['phone'],
                      });
                    }
                  }
                }

                final debtData = {
                  'details': debt['details'],
                  'user_id': userId,
                  'material': debt['material'],
                  'quantity': debt['quantity'],
                  'price': debt['price'],
                  'is_owed': debt['is_owed'],
                  'currency_id': debt['currency_id'],
                };

                if (index != null) {
                  await _dbHelper.updateDebt(_debts[index]['id'], debtData);
                } else {
                  await _dbHelper.insertDebt(debtData);
                }

                if (mounted) {
                  await _loadDebts();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving debt: $e')),
                  );
                }
              }
            },
          ),
    );
  }

  void _showDeleteConfirmation(int index) {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final title = languageProvider.translate('debts.delete_debt');
    final content = languageProvider.translate('debts.delete_confirm');
    final cancelText = languageProvider.translate('debts.cancel');
    final deleteText = languageProvider.translate('debts.delete');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ConfirmationDialog(
            title: title,
            content: content,
            confirmText: deleteText,
            cancelText: cancelText,
            confirmButtonColor: Colors.red,
            onConfirm: () async {
              try {
                if (!mounted) return;

                // Get the debt ID before deletion
                final debtId = _debts[index]['id'];

                // Delete the debt from database
                await _dbHelper.deleteDebt(debtId);

                if (!mounted) return;

                // Update the UI
                setState(() {
                  _debts.removeAt(index);
                  _invalidateCache(); // Invalidate cached totals

                  // Reset currency selection if needed
                  if (_selectedSummaryCurrencyId != null &&
                      !_currencies.any(
                        (c) => c['id'] == _selectedSummaryCurrencyId,
                      ) &&
                      _selectedSummaryCurrencyId != ALL_CURRENCIES_ID) {
                    _selectedSummaryCurrencyId =
                        _currencies.isNotEmpty
                            ? _currencies.first['id']
                            : ALL_CURRENCIES_ID;
                  }
                });

                // Close the dialog
                Navigator.of(context).pop();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      languageProvider.translate('debts.deleted_successfully'),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );

                // If this was the last debt and we're viewing a specific user's debts,
                // navigate back to the previous screen
                if (_debts.isEmpty && widget.userId != null) {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              } catch (e) {
                if (!mounted) return;

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${languageProvider.translate('debts.error_deleting')}: $e',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
    );
  }

  Widget _buildEmptyState() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            languageProvider.translate('debts.no_debts'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCardView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _debts.length,
      itemBuilder: (context, index) {
        final debt = _debts[index];
        final quantity =
            debt['quantity'] is String
                ? double.tryParse(debt['quantity']) ?? 0.0
                : (debt['quantity'] is int
                    ? debt['quantity'].toDouble()
                    : debt['quantity'] ?? 0.0);
        final price =
            debt['price'] is String
                ? double.tryParse(debt['price']) ?? 0.0
                : (debt['price'] is int
                    ? debt['price'].toDouble()
                    : debt['price'] ?? 0.0);
        return CardWidget(
          title: debt['details'],
          userName: debt['user_name'],
          material: debt['material'],
          quantity: quantity,
          price: price,
          currencySymbol: debt['currency_symbol'] ?? 'SP',
          isOwed: debt['is_owed'] == 1,
          onEdit: () => _showEditDialog(index),
          onDelete: () => _showDeleteConfirmation(index),
          details: debt['details'],
        );
      },
    );
  }

  Widget _buildTableView() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final numberOfColumns = 7;
    final columnWidth = screenWidth / numberOfColumns;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: TableWidget(
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: columnWidth,
                      child: Text(
                        languageProvider.translate('debts.details'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: columnWidth,
                      child: Text(
                        languageProvider.translate('debts.name'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: columnWidth,
                      child: Text(
                        languageProvider.translate('debts.material'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: columnWidth,
                      child: Text(
                        languageProvider.translate('debts.quantity'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: columnWidth,
                      child: Text(
                        languageProvider.translate('debts.price'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: columnWidth,
                      child: Text(
                        languageProvider.translate('debts.total_price'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: columnWidth,
                      child: Text(
                        languageProvider.translate('debts.actions'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                rows:
                    _debts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final debt = entry.value;
                      final quantity =
                          debt['quantity'] is String
                              ? double.tryParse(debt['quantity']) ?? 0.0
                              : (debt['quantity'] is int
                                  ? debt['quantity'].toDouble()
                                  : debt['quantity'] ?? 0.0);
                      final price =
                          debt['price'] is String
                              ? double.tryParse(debt['price']) ?? 0.0
                              : (debt['price'] is int
                                  ? debt['price'].toDouble()
                                  : debt['price'] ?? 0.0);
                      final totalPrice = quantity * price;
                      final currencySymbol = debt['currency_symbol'] ?? 'SP';
                      final isOwed = debt['is_owed'] == 1;

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: Text(
                                debt['details'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: Text(
                                debt['user_name'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: Text(
                                debt['material'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: Text(
                                debt['quantity'].toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: Text(
                                '${(debt['price'] is int ? debt['price'] : int.tryParse(debt['price'].toString()) ?? 0).toString()} $currencySymbol',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: Text(
                                '${totalPrice.toStringAsFixed(0)} $currencySymbol',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOwed ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: Center(
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder:
                                      (BuildContext context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.edit,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                languageProvider.translate(
                                                  'debts.edit',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                languageProvider.translate(
                                                  'debts.delete',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                  onSelected: (String value) {
                                    if (value == 'edit') {
                                      _showEditDialog(index);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(index);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
        _buildSummarySection(),
      ],
    );
  }

  void _calculateCurrencyTotals() {
    if (_cachedCurrencyTotals != null) return;

    Map<int, Map<String, double>> currencyTotals = {};

    for (var debt in _debts) {
      final currencyId = debt['currency_id'];
      final quantity =
          debt['quantity'] is String
              ? double.tryParse(debt['quantity']) ?? 0.0
              : (debt['quantity'] is int
                  ? debt['quantity'].toDouble()
                  : debt['quantity'] ?? 0.0);
      final price =
          debt['price'] is String
              ? double.tryParse(debt['price']) ?? 0.0
              : (debt['price'] is int
                  ? debt['price'].toDouble()
                  : debt['price'] ?? 0.0);
      final total = quantity * price;
      final isOwed = debt['is_owed'] == 1;

      if (!currencyTotals.containsKey(currencyId)) {
        currencyTotals[currencyId] = {'owed': 0.0, 'owing': 0.0};
      }

      if (isOwed) {
        currencyTotals[currencyId]!['owed'] =
            currencyTotals[currencyId]!['owed']! + total;
      } else {
        currencyTotals[currencyId]!['owing'] =
            currencyTotals[currencyId]!['owing']! + total;
      }
    }

    _cachedCurrencyTotals = currencyTotals;

    // Calculate totals in main currency (SP)
    double totalOwedInSP = 0;
    double totalOwingInSP = 0;

    for (var entry in currencyTotals.entries) {
      final currency = _currencies.firstWhere(
        (c) => c['id'] == entry.key,
        orElse: () => {'id': 1, 'price': 1.0},
      );
      final conversionRate = currency['price'] ?? 1.0;
      totalOwedInSP += entry.value['owed']! * conversionRate;
      totalOwingInSP += entry.value['owing']! * conversionRate;
    }

    _cachedTotalOwedInSP = totalOwedInSP;
    _cachedTotalOwingInSP = totalOwingInSP;
  }

  void _invalidateCache() {
    _cachedCurrencyTotals = null;
    _cachedTotalOwedInSP = null;
    _cachedTotalOwingInSP = null;
  }

  @override
  void didUpdateWidget(DebtsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _invalidateCache();
    }
  }

  Widget _buildSummarySection() {
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Calculate totals if not cached
    _calculateCurrencyTotals();
    final currencyTotals = _cachedCurrencyTotals ?? {};
    final totalOwedInSP = _cachedTotalOwedInSP ?? 0.0;
    final totalOwingInSP = _cachedTotalOwingInSP ?? 0.0;
    final defaultCurrencyId =
        _currencies.isNotEmpty ? _currencies.first['id'] : ALL_CURRENCIES_ID;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isSummaryVisible
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.blue,
                ),
                onPressed: () {
                  setState(() {
                    _isSummaryVisible = !_isSummaryVisible;
                  });
                },
              ),
              const Icon(Icons.summarize, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                languageProvider.translate('debts.summary'),
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: _selectedSummaryCurrencyId,
                items: [
                  DropdownMenuItem<int>(
                    value: ALL_CURRENCIES_ID,
                    child: Text(
                      languageProvider.translate('debts.all_currencies'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ..._currencies.map((currency) {
                    return DropdownMenuItem<int>(
                      value: currency['id'],
                      child: Text(
                        '${currency['code']} (${currency['symbol']})',
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSummaryCurrencyId = value;
                  });
                },
                underline: Container(height: 2, color: Colors.blue),
              ),
            ],
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSummaryVisible ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isSummaryVisible ? 1.0 : 0.0,
              child:
                  _selectedSummaryCurrencyId != null
                      ? Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.currency_exchange,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedSummaryCurrencyId ==
                                            ALL_CURRENCIES_ID
                                        ? '${languageProvider.translate('debts.all_currencies')} (SP)'
                                        : '${_currencies.firstWhere((c) => c['id'] == _selectedSummaryCurrencyId, orElse: () => {'code': '', 'symbol': ''})['code']} (${_currencies.firstWhere((c) => c['id'] == _selectedSummaryCurrencyId, orElse: () => {'code': '', 'symbol': ''})['symbol']})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          languageProvider.translate(
                                            'debts.total_owed',
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedSummaryCurrencyId ==
                                                  ALL_CURRENCIES_ID
                                              ? '${totalOwedInSP.toStringAsFixed(0)} SP'
                                              : '${(currencyTotals[_selectedSummaryCurrencyId]?['owed'] ?? 0.0).toStringAsFixed(0)} ${_currencies.firstWhere((c) => c['id'] == _selectedSummaryCurrencyId, orElse: () => {'symbol': 'SP'})['symbol']}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey[300],
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          languageProvider.translate(
                                            'debts.total_owing',
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedSummaryCurrencyId ==
                                                  ALL_CURRENCIES_ID
                                              ? '${totalOwingInSP.toStringAsFixed(0)} SP'
                                              : '${(currencyTotals[_selectedSummaryCurrencyId]?['owing'] ?? 0.0).toStringAsFixed(0)} ${_currencies.firstWhere((c) => c['id'] == _selectedSummaryCurrencyId, orElse: () => {'symbol': 'SP'})['symbol']}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (_selectedSummaryCurrencyId ==
                                                      ALL_CURRENCIES_ID
                                                  ? (totalOwingInSP -
                                                      totalOwedInSP)
                                                  : ((currencyTotals[_selectedSummaryCurrencyId]?['owing'] ??
                                                          0.0) -
                                                      (currencyTotals[_selectedSummaryCurrencyId]?['owed'] ??
                                                          0.0))) >
                                              0
                                          ? Colors.green[50]
                                          : Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      languageProvider.translate('debts.net'),
                                      style: TextStyle(
                                        color:
                                            (_selectedSummaryCurrencyId ==
                                                            ALL_CURRENCIES_ID
                                                        ? (totalOwingInSP -
                                                            totalOwedInSP)
                                                        : ((currencyTotals[_selectedSummaryCurrencyId]?['owing'] ??
                                                                0.0) -
                                                            (currencyTotals[_selectedSummaryCurrencyId]?['owed'] ??
                                                                0.0))) >
                                                    0
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _selectedSummaryCurrencyId ==
                                              ALL_CURRENCIES_ID
                                          ? '${(totalOwingInSP - totalOwedInSP).toStringAsFixed(0)} SP'
                                          : '${((currencyTotals[_selectedSummaryCurrencyId]?['owing'] ?? 0.0) - (currencyTotals[_selectedSummaryCurrencyId]?['owed'] ?? 0.0)).toStringAsFixed(0)} ${_currencies.firstWhere((c) => c['id'] == _selectedSummaryCurrencyId, orElse: () => {'symbol': 'SP'})['symbol']}',
                                      style: TextStyle(
                                        color:
                                            (_selectedSummaryCurrencyId ==
                                                            ALL_CURRENCIES_ID
                                                        ? (totalOwingInSP -
                                                            totalOwedInSP)
                                                        : ((currencyTotals[_selectedSummaryCurrencyId]?['owing'] ??
                                                                0.0) -
                                                            (currencyTotals[_selectedSummaryCurrencyId]?['owed'] ??
                                                                0.0))) >
                                                    0
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final title =
        widget.userName != null
            ? '${languageProvider.translate('debts.title')} (${widget.userName})'
            : languageProvider.translate('debts.title');

    return BaseScreen(
      title: title,
      showBackButton: widget.userId != null,
      actions: [
        IconButton(
          icon: Icon(_isCardView ? Icons.table_chart : Icons.view_agenda),
          onPressed: () {
            setState(() {
              _isCardView = !_isCardView;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showEditDialog(),
        ),
      ],
      body:
          _debts.isEmpty
              ? _buildEmptyState()
              : _isCardView
              ? Column(
                children: [
                  Expanded(child: _buildCardView()),
                  _buildSummarySection(),
                ],
              )
              : _buildTableView(),
    );
  }
}
