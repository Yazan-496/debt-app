import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  static const String _backupDirName = 'DebtAppBackups';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Request manage external storage permission
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<String> getBackupDirectoryPath() async {
    final dir = await _getBackupDir();
    return dir.path;
  }

  Future<Directory> _getBackupDir() async {
    if (!await _requestStoragePermission()) {
      throw Exception('Storage permission denied');
    }

    // Get the public external storage directory (usually /storage/emulated/0/DebtAppBackups)
    final externalDir = Directory('/storage/emulated/0/$_backupDirName');
    if (!await externalDir.exists()) {
      await externalDir.create(recursive: true);
    }
    return externalDir;
  }

  Future<String> createBackup() async {
    final dir = await _getBackupDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupDir = Directory('${dir.path}/backup_$timestamp');
    await backupDir.create(recursive: true);

    final db = await _dbHelper.database;

    // Create backup files for each table
    final tableNames = ['currencies', 'users', 'items', 'item_prices', 'debts'];
    for (final table in tableNames) {
      final data = await db.query(table);
      final file = File('${backupDir.path}/$table.json');
      await file.writeAsString(jsonEncode(data));
    }

    return backupDir.path;
  }

  // Get list of available backups
  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    final backupDir = await _getBackupDir();
    final List<Map<String, dynamic>> backups = [];

    if (!await backupDir.exists()) {
      return backups;
    }

    await for (final entity in backupDir.list()) {
      if (entity is Directory && entity.path.contains('backup_')) {
        final timestamp = int.tryParse(entity.path.split('backup_').last);
        if (timestamp != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          backups.add({
            'path': entity.path,
            'timestamp': timestamp,
            'date': date,
          });
        }
      }
    }

    // Sort backups by timestamp (newest first)
    backups.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    return backups;
  }

  // Restore data from backup
  Future<void> restoreFromBackup(String backupPath) async {
    final Database db = await _dbHelper.database;

    // Start transaction
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('debts');
      await txn.delete('item_prices');
      await txn.delete('items');
      await txn.delete('users');
      await txn.delete('currencies');

      // Restore each table
      final tables = ['currencies', 'users', 'items', 'item_prices', 'debts'];
      for (final table in tables) {
        final file = File('$backupPath/$table.json');
        if (await file.exists()) {
          final data = jsonDecode(await file.readAsString()) as List;
          for (final row in data) {
            await txn.insert(table, row as Map<String, dynamic>);
          }
        }
      }
    });
  }

  // Delete a backup
  Future<void> deleteBackup(String backupPath) async {
    final dir = Directory(backupPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
