import 'package:sqflite/sqflite.dart';
import 'base_database_helper.dart';

class UserOperations {
  final BaseDatabaseHelper _dbHelper = BaseDatabaseHelper();

  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await _dbHelper.database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await _dbHelper.database;
    return await db.query('users', orderBy: 'name ASC');
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    Database db = await _dbHelper.database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
