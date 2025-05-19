import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';
import '../providers/language_provider.dart';
import '../database/database_helper.dart';
import '../widgets/table_widget.dart';
import '../widgets/dialog_widget.dart';
import '../utils/number_formatter.dart';
import 'package:provider/provider.dart';

class CurrenciesPage extends StatefulWidget {
  const CurrenciesPage({super.key});

  @override
  State<CurrenciesPage> createState() => _CurrenciesPageState();
}

class _CurrenciesPageState extends State<CurrenciesPage> {
  final List<Map<String, dynamic>> _currencies = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _symbolController = TextEditingController();
  final _priceController = TextEditingController();
  int? _editingIndex;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    final currencies = await _dbHelper.getCurrencies();
    setState(() {
      _currencies.clear();
      _currencies.addAll(currencies);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _symbolController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showEditDialog([int? index]) {
    if (!mounted) return;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final title = languageProvider.translate(
      index != null ? 'currencies.edit_currency' : 'currencies.add_currency',
    );
    final nameLabel = languageProvider.translate('currencies.name');
    final codeLabel = languageProvider.translate('currencies.code');
    final symbolLabel = languageProvider.translate('currencies.symbol');
    final priceLabel = languageProvider.translate('currencies.price');
    final cancelText = languageProvider.translate('common.cancel');
    final saveText = languageProvider.translate('common.save');

    if (index != null) {
      final currency = _currencies[index];
      _nameController.text = currency['name'];
      _codeController.text = currency['code'];
      _symbolController.text = currency['symbol'];
      _priceController.text = currency['price'].toString();
      _editingIndex = index;
    } else {
      _nameController.clear();
      _codeController.clear();
      _symbolController.clear();
      _priceController.clear();
      _editingIndex = null;
    }

    final dialogContext = context;
    showDialog(
      context: dialogContext,
      builder:
          (context) => ModalWidget(
            title: title,
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: nameLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: codeLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _symbolController,
                    decoration: InputDecoration(
                      labelText: symbolLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: priceLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(cancelText),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!mounted) return;
                  if (_formKey.currentState!.validate()) {
                    final currency = {
                      'name': _nameController.text,
                      'code': _codeController.text,
                      'symbol': _symbolController.text,
                      'price': double.parse(_priceController.text),
                    };

                    if (_editingIndex != null) {
                      await _dbHelper.updateCurrency(
                        _currencies[_editingIndex!]['id'],
                        currency,
                      );
                    } else {
                      await _dbHelper.insertCurrency(currency);
                    }

                    await _loadCurrencies();
                    if (mounted) {
                      Navigator.pop(dialogContext);
                    }
                  }
                },
                child: Text(saveText),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(int index) {
    if (!mounted) return;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    // Check if currency symbol is '$' or 'sp'
    final currencySymbol = _currencies[index]['symbol'];
    if (currencySymbol == '\$' || currencySymbol.toLowerCase() == 'sp') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.translate('currencies.cannot_delete_default'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final title = languageProvider.translate('currencies.delete_currency');
    final content = languageProvider.translate(
      'currencies.delete_currency_confirmation',
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
              await _dbHelper.deleteCurrency(_currencies[index]['id']);
              await _loadCurrencies();
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
          Icon(Icons.currency_exchange, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            languageProvider.translate('currencies.no_currencies'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final numberOfColumns = 5;
    final columnWidth = screenWidth / numberOfColumns;

    final columns = [
      DataColumn(
        label: SizedBox(
          width: columnWidth,
          child: Text(
            languageProvider.translate('currencies.name'),
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
            languageProvider.translate('currencies.code'),
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
            languageProvider.translate('currencies.symbol'),
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
            languageProvider.translate('currencies.price'),
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
        _currencies.asMap().entries.map((entry) {
          final index = entry.key;
          final currency = entry.value;

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: columnWidth,
                  child: Text(
                    currency['name'],
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
                    currency['code'],
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
                    currency['symbol'],
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
                    NumberFormatter.formatPrice(currency['price']),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    languageProvider.translate('common.edit'),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.delete, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    languageProvider.translate('common.delete'),
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
        }).toList();

    return TableWidget(
      columns: columns,
      rows: rows,
      headingRowColor: Colors.green[50],
      dataRowColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return BaseScreen(
      title: languageProvider.translate('currencies.title'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showEditDialog(),
        ),
      ],
      body: _currencies.isEmpty ? _buildEmptyState() : _buildTableView(),
    );
  }
}
