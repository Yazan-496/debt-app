import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';
import '../providers/language_provider.dart';
import '../database/database_helper.dart';
import '../widgets/table_widget.dart';
import '../widgets/dialog_widget.dart';
import '../utils/number_formatter.dart';
import 'package:provider/provider.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final List<Map<String, dynamic>> _items = [];
  final List<Map<String, dynamic>> _currencies = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final items = await _dbHelper.getItems();
      if (!mounted) return;
      setState(() {
        _items.clear();
        _items.addAll(items);
      });

      try {
        final currencies = await _dbHelper.getCurrencies();
        if (!mounted) return;
        setState(() {
          _currencies.clear();
          _currencies.addAll(currencies);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading currencies: $e')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
      }
    }
  }

  Future<void> _handleItemSave(Map<String, dynamic> item) async {
    try {
      // Create a new map with the item data to avoid modifying the original
      final itemData = {
        'name': item['name'],
        'prices': List<Map<String, dynamic>>.from(item['prices']),
      };

      if (_editingIndex != null) {
        await _dbHelper.updateItem(_items[_editingIndex!]['id'], itemData);
      } else {
        await _dbHelper.insertItem(itemData);
      }
      if (mounted) {
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving item: $e')));
      }
    }
  }

  void _showEditDialog([int? index]) {
    if (!mounted) return;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final title = languageProvider.translate(
      index != null ? 'items.edit_item' : 'items.add_item',
    );
    final nameLabel = languageProvider.translate('items.name');
    final cancelText = languageProvider.translate('common.cancel');
    final saveText = languageProvider.translate('common.save');

    _editingIndex = index;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _EditItemDialog(
          title: title,
          nameLabel: nameLabel,
          cancelText: cancelText,
          saveText: saveText,
          currencies: _currencies,
          initialName: index != null ? _items[index]['name'] : '',
          initialPrices: index != null ? _items[index]['prices'] : [],
          onSave: (item) async {
            Navigator.pop(dialogContext);
            await _handleItemSave(item);
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(int index) {
    if (!mounted) return;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final title = languageProvider.translate('items.delete_item');
    final content = languageProvider.translate(
      'items.delete_item_confirmation',
    );
    final confirmText = languageProvider.translate('common.delete');
    final cancelText = languageProvider.translate('common.cancel');

    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: title,
            content: content,
            confirmText: confirmText,
            cancelText: cancelText,
            confirmButtonColor: Colors.red,
            onConfirm: () async {
              await _dbHelper.deleteItem(_items[index]['id']);
              await _loadData();
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
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            languageProvider.translate('items.no_items'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final numberOfColumns = _currencies.length + 3; // name + prices + actions
    final columnWidth = screenWidth / numberOfColumns;

    final columns = [
      DataColumn(
        label: SizedBox(
          width: columnWidth,
          child: Text(
            languageProvider.translate('items.name'),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      ..._currencies.map(
        (currency) => DataColumn(
          label: SizedBox(
            width: columnWidth,
            child: Text(
              '${languageProvider.translate('items.price')} (${currency['symbol']})',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: columnWidth,
          child: Text(
            languageProvider.translate('common.created_at'),
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
            languageProvider.translate('common.actions'),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];

    final rows =
        _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final createdAt = DateTime.parse(item['created_at']);

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: columnWidth,
                  child: Text(
                    item['name'],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ..._currencies.map((currency) {
                final price = item['prices'].firstWhere(
                  (p) => p['currency_id'] == currency['id'],
                  orElse: () => {'price': 0.0},
                );
                return DataCell(
                  SizedBox(
                    width: columnWidth,
                    child: Text(
                      NumberFormatter.formatPrice(price['price']),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
              DataCell(
                SizedBox(
                  width: columnWidth,
                  child: Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: columnWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(index);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(index);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      languageProvider.translate('common.edit'),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      languageProvider.translate(
                                        'common.delete',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList();

    return TableWidget(columns: columns, rows: rows);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return BaseScreen(
      title: languageProvider.translate('items.title'),
      body: _items.isEmpty ? _buildEmptyState() : _buildTableView(),
      actions:
          _currencies.isNotEmpty
              ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showEditDialog(),
                ),
              ]
              : null,
    );
  }
}

class _EditItemDialog extends StatefulWidget {
  final String title;
  final String nameLabel;
  final String cancelText;
  final String saveText;
  final String initialName;
  final List<Map<String, dynamic>> initialPrices;
  final List<Map<String, dynamic>> currencies;
  final Function(Map<String, dynamic>) onSave;

  const _EditItemDialog({
    required this.title,
    required this.nameLabel,
    required this.cancelText,
    required this.saveText,
    required this.initialName,
    required this.initialPrices,
    required this.currencies,
    required this.onSave,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TextEditingController _nameController;
  late List<TextEditingController> _priceControllers;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  late LanguageProvider _languageProvider;

  @override
  void initState() {
    super.initState();
    _languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    _nameController = TextEditingController(text: widget.initialName);
    _priceControllers =
        widget.currencies.map((currency) {
          final initialPrice = widget.initialPrices.firstWhere(
            (p) => p['currency_id'] == currency['id'],
            orElse: () => {'price': ''},
          );
          return TextEditingController(
            text: initialPrice['price']?.toString() ?? '',
          );
        }).toList();

    // Add listeners to all price controllers
    for (var controller in _priceControllers) {
      controller.addListener(_checkPrices);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _priceControllers) {
      controller.removeListener(_checkPrices);
      controller.dispose();
    }
    super.dispose();
  }

  void _checkPrices() {
    if (_hasAtLeastOnePrice() &&
        _errorMessage ==
            _languageProvider.translate('items.at_least_one_price_required')) {
      setState(() => _errorMessage = null);
    }
  }

  bool _hasAtLeastOnePrice() {
    return _priceControllers.any(
      (controller) =>
          controller.text.isNotEmpty &&
          double.tryParse(controller.text) != null,
    );
  }

  Future<bool> _isNameUnique(String name) async {
    if (name == widget.initialName)
      return true; // Skip check if name hasn't changed
    final dbHelper = DatabaseHelper();
    final items = await dbHelper.getItems();
    return !items.any(
      (item) => item['name'].toLowerCase() == name.toLowerCase(),
    );
  }

  void _setErrorMessage(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: widget.nameLabel,
                  errorMaxLines: 2,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return languageProvider.translate('common.required_field');
                  }
                  return null;
                },
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    final isUnique = await _isNameUnique(value);
                    if (!mounted) return;
                    setState(() {
                      if (!isUnique) {
                        _setErrorMessage(
                          languageProvider.translate(
                            'items.name_already_exists',
                          ),
                        );
                      } else {
                        _errorMessage = null;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ...widget.currencies.asMap().entries.map((entry) {
                final index = entry.key;
                final currency = entry.value;
                return Column(
                  children: [
                    TextFormField(
                      controller: _priceControllers[index],
                      decoration: InputDecoration(
                        labelText:
                            '${languageProvider.translate('items.price')} (${currency['symbol']})',
                        errorMaxLines: 2,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null; // Allow empty values for individual currencies
                        }
                        if (double.tryParse(value) == null) {
                          return languageProvider.translate(
                            'common.invalid_number',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelText),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (!_hasAtLeastOnePrice()) {
                _setErrorMessage(
                  languageProvider.translate(
                    'items.at_least_one_price_required',
                  ),
                );
                return;
              }

              if (_errorMessage != null) {
                return;
              }

              // Get SP currency for reference
              final spCurrency = widget.currencies.firstWhere(
                (currency) => currency['code'] == 'SP',
                orElse: () => {'id': 0, 'price': 1.0},
              );

              final prices =
                  widget.currencies.asMap().entries.map((entry) {
                    final index = entry.key;
                    final currency = entry.value;
                    final priceText = _priceControllers[index].text;

                    // If price is empty, try to get it from SP price
                    if (priceText.isEmpty) {
                      final spIndex = widget.currencies.indexWhere(
                        (c) => c['id'] == spCurrency['id'],
                      );
                      if (spIndex != -1 &&
                          _priceControllers[spIndex].text.isNotEmpty) {
                        final spPrice = double.parse(
                          _priceControllers[spIndex].text,
                        );
                        final currencyRate = currency['price'] as double;
                        // If converting from SP to other currency, divide by rate
                        // If converting to SP, multiply by rate
                        if (currency['id'] == spCurrency['id']) {
                          return {
                            'currency_id': currency['id'],
                            'price': spPrice,
                          };
                        } else {
                          return {
                            'currency_id': currency['id'],
                            'price': spPrice / currencyRate,
                          };
                        }
                      }
                    }

                    return {
                      'currency_id': currency['id'],
                      'price':
                          priceText.isEmpty ? 0.0 : double.parse(priceText),
                    };
                  }).toList();

              final item = {'name': _nameController.text, 'prices': prices};
              widget.onSave(item);
            }
          },
          child: Text(widget.saveText),
        ),
      ],
    );
  }
}
