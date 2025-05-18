import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dept_app.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE currencies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        symbol TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 1.0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        details TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        material TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price INTEGER NOT NULL,
        currency_id INTEGER NOT NULL,
        is_owed INTEGER NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (currency_id) REFERENCES currencies (id)
      )
    ''');

    // Insert default currencies
    await db.insert('currencies', {
      'name': 'Syrian Pound',
      'code': 'SP',
      'symbol': 'SP',
      'price': 1.0,
    });
    await db.insert('currencies', {
      'name': 'US Dollar',
      'code': 'USD',
      'symbol': '\$',
      'price': 10000.0,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create users table
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create temporary debts table with new schema
      await db.execute('''
        CREATE TABLE debts_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          details TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          material TEXT NOT NULL,
          quantity REAL NOT NULL,
          price REAL NOT NULL,
          is_owed INTEGER NOT NULL DEFAULT 1,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Get all existing debts
      List<Map<String, dynamic>> oldDebts = await db.query('debts');

      // For each debt, create a user and insert the debt with the new user_id
      for (var debt in oldDebts) {
        // Insert user
        int userId = await db.insert('users', {
          'name': debt['name'],
          'created_at': debt['created_at'],
        });

        // Insert debt with new user_id
        await db.insert('debts_new', {
          'details': debt['details'],
          'user_id': userId,
          'material': debt['material'],
          'quantity': debt['quantity'],
          'price': debt['price'],
          'is_owed': 1, // Default value for existing debts
          'created_at': debt['created_at'],
        });
      }

      // Drop old debts table
      await db.execute('DROP TABLE debts');

      // Rename new debts table
      await db.execute('ALTER TABLE debts_new RENAME TO debts');
    }
    if (oldVersion < 3) {
      try {
        // First try to add the column
        await db.execute(
          'ALTER TABLE debts ADD COLUMN is_owed INTEGER NOT NULL DEFAULT 1',
        );
      } catch (e) {
        // If the column already exists, ignore the error
        if (!e.toString().contains('duplicate column name')) {
          rethrow;
        }
      }
    }
    if (oldVersion < 4) {
      // Drop currencies table if it exists
      try {
        await db.execute('DROP TABLE IF EXISTS currencies');
      } catch (e) {
        // Ignore error if table doesn't exist
      }

      // Create currencies table with all required columns
      await db.execute('''
        CREATE TABLE currencies(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          symbol TEXT NOT NULL,
          price REAL NOT NULL DEFAULT 1.0,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Insert default currencies
      await db.insert('currencies', {
        'name': 'Syrian Pound',
        'code': 'SP',
        'symbol': 'SP',
        'price': 1.0,
      });
      await db.insert('currencies', {
        'name': 'US Dollar',
        'code': 'USD',
        'symbol': '\$',
        'price': 1.0,
      });

      // Add currency_id column to debts table
      await db.execute(
        'ALTER TABLE debts ADD COLUMN currency_id INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 5) {
      // Ensure currencies table has all required columns
      try {
        await db.execute(
          'ALTER TABLE currencies ADD COLUMN price REAL NOT NULL DEFAULT 1.0',
        );
      } catch (e) {
        // Ignore error if column already exists
      }
    }
    if (oldVersion < 6) {
      // Create temporary debts table with new schema
      await db.execute('''
        CREATE TABLE debts_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          details TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          material TEXT NOT NULL,
          quantity REAL NOT NULL,
          price REAL NOT NULL,
          currency_id INTEGER NOT NULL,
          is_owed INTEGER NOT NULL DEFAULT 1,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (currency_id) REFERENCES currencies (id)
        )
      ''');

      // Copy data from old table to new table
      await db.execute('''
        INSERT INTO debts_new
        SELECT id, details, user_id, material, CAST(quantity AS REAL), price, currency_id, is_owed, created_at
        FROM debts
      ''');

      // Drop old table
      await db.execute('DROP TABLE debts');

      // Rename new table
      await db.execute('ALTER TABLE debts_new RENAME TO debts');
    }
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query('users', orderBy: 'name ASC');
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    Database db = await database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Debt operations
  Future<int> insertDebt(Map<String, dynamic> debt) async {
    Database db = await database;
    return await db.insert('debts', debt);
  }

  Future<List<Map<String, dynamic>>> getDebts() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT debts.*, users.name as user_name, users.phone as user_phone, currencies.code as currency_code, currencies.symbol as currency_symbol
      FROM debts 
      JOIN users ON debts.user_id = users.id 
      JOIN currencies ON debts.currency_id = currencies.id
      ORDER BY debts.created_at DESC
    ''');
  }

  Future<int> updateDebt(int id, Map<String, dynamic> debt) async {
    Database db = await database;
    return await db.update('debts', debt, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDebt(int id) async {
    Database db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // Currency operations
  Future<int> insertCurrency(Map<String, dynamic> currency) async {
    Database db = await database;
    return await db.insert('currencies', currency);
  }

  Future<List<Map<String, dynamic>>> getCurrencies() async {
    Database db = await database;
    return await db.query('currencies', orderBy: 'code ASC');
  }

  Future<int> updateCurrency(int id, Map<String, dynamic> currency) async {
    Database db = await database;
    return await db.update(
      'currencies',
      currency,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCurrency(int id) async {
    Database db = await database;
    return await db.delete('currencies', where: 'id = ?', whereArgs: [id]);
  }
}
