import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BaseDatabaseHelper {
  static final BaseDatabaseHelper _instance = BaseDatabaseHelper._internal();
  static Database? _database;

  factory BaseDatabaseHelper() => _instance;

  BaseDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dept_app.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create currencies table first
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

    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create items table
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create item_prices table
    await db.execute('''
      CREATE TABLE item_prices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        currency_id INTEGER NOT NULL,
        price REAL NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE,
        FOREIGN KEY (currency_id) REFERENCES currencies (id)
      )
    ''');

    // Create debts table
    await db.execute('''
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        details TEXT,
        user_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price INTEGER NOT NULL,
        currency_id INTEGER NOT NULL,
        is_owed INTEGER NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (currency_id) REFERENCES currencies (id),
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
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
          item_id INTEGER NOT NULL,
          quantity REAL NOT NULL,
          price REAL NOT NULL,
          is_owed INTEGER NOT NULL DEFAULT 1,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
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
          'item_id': debt['item_id'],
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
        'price': 10000.0,
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
          item_id INTEGER NOT NULL,
          quantity REAL NOT NULL,
          price REAL NOT NULL,
          currency_id INTEGER NOT NULL,
          is_owed INTEGER NOT NULL DEFAULT 1,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (currency_id) REFERENCES currencies (id),
          FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
        )
      ''');

      // Get all existing debts
      List<Map<String, dynamic>> oldDebts = await db.query('debts');

      // For each debt, create or find the item and update the debt
      for (var debt in oldDebts) {
        // Find or create the item
        List<Map<String, dynamic>> existingItems = await db.query(
          'items',
          where: 'name = ?',
          whereArgs: [debt['item']],
        );

        int itemId;
        if (existingItems.isEmpty) {
          // Create new item if it doesn't exist
          itemId = await db.insert('items', {
            'name': debt['item'],
            'created_at': debt['created_at'],
          });
        } else {
          itemId = existingItems.first['id'];
        }

        // Insert debt with new item_id
        await db.insert('debts_new', {
          'details': debt['details'],
          'user_id': debt['user_id'],
          'item_id': itemId,
          'quantity': debt['quantity'],
          'price': debt['price'],
          'currency_id': debt['currency_id'],
          'is_owed': debt['is_owed'],
          'created_at': debt['created_at'],
        });
      }

      // Drop old table
      await db.execute('DROP TABLE debts');

      // Rename new table
      await db.execute('ALTER TABLE debts_new RENAME TO debts');
    }
  }
}
