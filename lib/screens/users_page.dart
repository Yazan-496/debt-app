import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';
import '../providers/language_provider.dart';
import '../database/database_helper.dart';
import '../widgets/table_widget.dart';
import '../widgets/dialog_widget.dart';
import 'package:provider/provider.dart';
import '../screens/debts_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final List<Map<String, dynamic>> _users = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    final users = await _dbHelper.getUsers();
    if (!mounted) return;
    setState(() {
      _users.clear();
      _users.addAll(users);
    });
  }

  Future<void> _handleUserSave(Map<String, dynamic> user) async {
    try {
      if (_editingIndex != null) {
        await _dbHelper.updateUser(_users[_editingIndex!]['id'], user);
      } else {
        await _dbHelper.insertUser(user);
      }
      if (mounted) {
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      index != null ? 'users.edit_user' : 'users.add_user',
    );
    final nameLabel = languageProvider.translate('users.name');
    final cancelText = languageProvider.translate('common.cancel');
    final saveText = languageProvider.translate('common.save');

    _editingIndex = index;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _EditUserDialog(
          title: title,
          nameLabel: nameLabel,
          cancelText: cancelText,
          saveText: saveText,
          phoneLabel: languageProvider.translate('users.phone'),
          initialName: index != null ? _users[index]['name'] : '',
          initialPhone: index != null ? _users[index]['phone'] ?? '' : '',
          onSave: (user) async {
            Navigator.pop(dialogContext);
            await _handleUserSave(user);
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
    final title = languageProvider.translate('users.delete_user');
    final content = languageProvider.translate(
      'users.delete_user_confirmation',
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
              await _dbHelper.deleteUser(_users[index]['id']);
              await _loadUsers();
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
          Icon(Icons.people, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            languageProvider.translate('users.no_users'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final numberOfColumns = 4;
    final columnWidth = screenWidth / numberOfColumns;

    final columns = [
      DataColumn(
        label: SizedBox(
          width: columnWidth,
          child: Text(
            languageProvider.translate('users.name'),
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
            languageProvider.translate('users.phone'),
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
        _users.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          final createdAt = DateTime.parse(user['created_at']);

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: columnWidth,
                  child: Text(
                    user['name'],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DebtsPage(
                            userId: user['id'],
                            userName: user['name'],
                          ),
                    ),
                  );
                },
              ),
              DataCell(
                SizedBox(
                  width: columnWidth,
                  child: Text(
                    user['phone'] ?? '',
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
      title: languageProvider.translate('users.title'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showEditDialog(),
        ),
      ],
      body: _users.isEmpty ? _buildEmptyState() : _buildTableView(),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final String title;
  final String nameLabel;
  final String phoneLabel;
  final String cancelText;
  final String saveText;
  final String initialName;
  final String initialPhone;
  final Function(Map<String, dynamic>) onSave;

  const _EditUserDialog({
    required this.title,
    required this.nameLabel,
    required this.phoneLabel,
    required this.cancelText,
    required this.saveText,
    required this.initialName,
    required this.initialPhone,
    required this.onSave,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalWidget(
      title: widget.title,
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: widget.nameLabel,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: widget.phoneLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave({
                'name': _nameController.text,
                'phone': _phoneController.text,
              });
            }
          },
          child: Text(widget.saveText),
        ),
      ],
    );
  }
}
