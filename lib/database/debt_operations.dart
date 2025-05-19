import 'package:sqflite/sqflite.dart';
import 'base_database_helper.dart';

class DebtOperations {
  final BaseDatabaseHelper _dbHelper = BaseDatabaseHelper();

  Future<int> insertDebt(Map<String, dynamic> debt) async {
    Database db = await _dbHelper.database;
    return await db.insert('debts', debt);
  }

  Future<List<Map<String, dynamic>>> getDebts() async {
    Database db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT debts.*, users.name as user_name, users.phone as user_phone, 
             currencies.code as currency_code, currencies.symbol as currency_symbol,
             items.name as item, items.id as item_id
      FROM debts 
      JOIN users ON debts.user_id = users.id 
      JOIN currencies ON debts.currency_id = currencies.id
      JOIN items ON debts.item_id = items.id
      ORDER BY debts.created_at DESC
    ''');
  }

  Future<int> updateDebt(int id, Map<String, dynamic> debt) async {
    Database db = await _dbHelper.database;
    return await db.update('debts', debt, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDebt(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }
}
