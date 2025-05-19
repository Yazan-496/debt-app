import 'package:sqflite/sqflite.dart';
import 'base_database_helper.dart';

class CurrencyOperations {
  final BaseDatabaseHelper _dbHelper = BaseDatabaseHelper();

  Future<int> insertCurrency(Map<String, dynamic> currency) async {
    Database db = await _dbHelper.database;
    return await db.insert('currencies', currency);
  }

  Future<List<Map<String, dynamic>>> getCurrencies() async {
    Database db = await _dbHelper.database;
    final results = await db.query('currencies', orderBy: 'created_at ASC');
    // Create a new list with copied maps to avoid read-only issues
    return results.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<int> updateCurrency(int id, Map<String, dynamic> currency) async {
    Database db = await _dbHelper.database;
    return await db.update(
      'currencies',
      currency,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCurrency(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete('currencies', where: 'id = ?', whereArgs: [id]);
  }
}
