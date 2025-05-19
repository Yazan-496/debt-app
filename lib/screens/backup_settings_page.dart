import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';
import '../providers/language_provider.dart';
import '../services/backup_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final BackupService _backupService = BackupService();
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final backups = await _backupService.getAvailableBackups();
      if (mounted) {
        setState(() {
          _backups = backups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading backups: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createBackup() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _backupService.createBackup();
      await _loadBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating backup: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreBackup(String backupPath) async {
    if (!mounted) return;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final confirmText = languageProvider.translate('backup.restore_confirm');
    final cancelText = languageProvider.translate('common.cancel');
    final restoreText = languageProvider.translate('backup.restore');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(languageProvider.translate('backup.restore_backup')),
            content: Text(confirmText),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelText),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(restoreText),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _backupService.restoreFromBackup(backupPath);
      await _loadBackups();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error restoring backup: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBackup(String backupPath) async {
    if (!mounted) return;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final confirmText = languageProvider.translate('backup.delete_confirm');
    final cancelText = languageProvider.translate('common.cancel');
    final deleteText = languageProvider.translate('backup.delete');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(languageProvider.translate('backup.delete_backup')),
            content: Text(confirmText),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelText),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(deleteText),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _backupService.deleteBackup(backupPath);
      await _loadBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting backup: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final title = languageProvider.translate('backup.title');
    final createBackupText = languageProvider.translate('backup.create_backup');
    final noBackupsText = languageProvider.translate('backup.no_backups');
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return BaseScreen(
      title: title,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _createBackup,
                      icon: const Icon(Icons.backup),
                      label: Text(createBackupText),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _backups.isEmpty
                            ? Center(child: Text(noBackupsText))
                            : ListView.builder(
                              itemCount: _backups.length,
                              itemBuilder: (context, index) {
                                final backup = _backups[index];
                                final date = backup['date'] as DateTime;
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: ListTile(
                                    title: Text(dateFormat.format(date)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.restore),
                                          onPressed:
                                              () => _restoreBackup(
                                                backup['path'] as String,
                                              ),
                                          tooltip: languageProvider.translate(
                                            'backup.restore',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed:
                                              () => _deleteBackup(
                                                backup['path'] as String,
                                              ),
                                          tooltip: languageProvider.translate(
                                            'backup.delete',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
