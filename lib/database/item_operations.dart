import 'package:sqflite/sqflite.dart';
import 'base_database_helper.dart';

class ItemOperations {
  final BaseDatabaseHelper _dbHelper = BaseDatabaseHelper();

  Future<int> insertItem(Map<String, dynamic> item) async {
    Database db = await _dbHelper.database;

    // Check if name is unique
    final existingItems = await db.query(
      'items',
      where: 'LOWER(name) = ?',
      whereArgs: [item['name'].toLowerCase()],
    );

    if (existingItems.isNotEmpty) {
      throw Exception('items.name_already_exists');
    }

    // Check if at least one price is provided
    final hasPrice = item['prices'].any(
      (price) => price['price'] is num && (price['price'] as num) > 0,
    );

    if (!hasPrice) {
      throw Exception('items.at_least_one_price_required');
    }

    int itemId = 0;

    try {
      await db.transaction((txn) async {
        itemId = await txn.insert('items', {'name': item['name']});

        // Get all currencies to access their rates
        final currencies = await txn.query('currencies');

        // Find SP currency
        final spCurrency = currencies.firstWhere((c) => c['code'] == 'SP');

        // Process each price entry
        for (var price in item['prices']) {
          final currency = currencies.firstWhere(
            (c) => c['id'] == price['currency_id'],
          );

          double finalPrice;
          if (price['price'] is num && (price['price'] as num) > 0) {
            // If price is provided, use it directly
            finalPrice = (price['price'] as num).toDouble();
          } else {
            // If price is missing, try to get it from other currencies
            finalPrice = 0.0;

            // First try to get SP price
            final spPrice = item['prices'].firstWhere(
              (p) => p['currency_id'] == spCurrency['id'],
              orElse: () => {'price': 0.0},
            );

            if (spPrice['price'] is num && (spPrice['price'] as num) > 0) {
              // If we have SP price, convert to this currency
              if (currency['id'] == spCurrency['id']) {
                finalPrice = (spPrice['price'] as num).toDouble();
              } else {
                // Converting from SP to other currency - divide by rate
                finalPrice =
                    (spPrice['price'] as num).toDouble() /
                    (currency['price'] as double);
              }
            } else {
              // If no SP price, try to find any other currency with price
              for (var otherPrice in item['prices']) {
                if (otherPrice['price'] is num &&
                    (otherPrice['price'] as num) > 0) {
                  final otherCurrency = currencies.firstWhere(
                    (c) => c['id'] == otherPrice['currency_id'],
                  );

                  if (currency['id'] == spCurrency['id']) {
                    // Converting to SP - multiply by rate
                    finalPrice =
                        (otherPrice['price'] as num).toDouble() *
                        (otherCurrency['price'] as double);
                  } else {
                    // Converting between non-SP currencies
                    // First convert to SP value, then to target currency
                    final spValue =
                        (otherPrice['price'] as num).toDouble() *
                        (otherCurrency['price'] as double);
                    finalPrice = spValue / (currency['price'] as double);
                  }
                  break;
                }
              }
            }
          }

          await txn.insert('item_prices', {
            'item_id': itemId,
            'currency_id': price['currency_id'],
            'price': finalPrice,
          });
        }
      });
    } catch (e) {
      throw Exception('items.save_error');
    }

    return itemId;
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    Database db = await _dbHelper.database;

    // Get all items
    final items = await db.query('items', orderBy: 'name ASC');

    // Create a new list with copied maps to avoid read-only issues
    final List<Map<String, dynamic>> mutableItems =
        items.map((item) => Map<String, dynamic>.from(item)).toList();

    // Get prices for each item
    for (var item in mutableItems) {
      final prices = await db.rawQuery(
        '''
        SELECT ip.*, c.code, c.symbol
        FROM item_prices ip
        JOIN currencies c ON ip.currency_id = c.id
        WHERE ip.item_id = ?
      ''',
        [item['id']],
      );

      // Create a new list with copied maps for prices
      item['prices'] =
          prices.map((price) => Map<String, dynamic>.from(price)).toList();
    }

    return mutableItems;
  }

  Future<int> updateItem(int id, Map<String, dynamic> item) async {
    Database db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'items',
        {'name': item['name']},
        where: 'id = ?',
        whereArgs: [id],
      );

      // Get all currencies to access their rates
      final currencies = await txn.query('currencies');

      // Find SP currency
      final spCurrency = currencies.firstWhere((c) => c['code'] == 'SP');

      // Delete existing prices
      await txn.delete('item_prices', where: 'item_id = ?', whereArgs: [id]);

      // Insert new prices
      for (var price in item['prices']) {
        final currency = currencies.firstWhere(
          (c) => c['id'] == price['currency_id'],
        );

        double finalPrice;
        if (price['price'] is num && (price['price'] as num) > 0) {
          // If price is provided, use it directly
          finalPrice = (price['price'] as num).toDouble();
        } else {
          // If price is missing, try to get it from other currencies
          finalPrice = 0.0;

          // First try to get SP price
          final spPrice = item['prices'].firstWhere(
            (p) => p['currency_id'] == spCurrency['id'],
            orElse: () => {'price': 0.0},
          );

          if (spPrice['price'] is num && (spPrice['price'] as num) > 0) {
            // If we have SP price, convert to this currency
            if (currency['id'] == spCurrency['id']) {
              finalPrice = (spPrice['price'] as num).toDouble();
            } else {
              finalPrice =
                  (spPrice['price'] as num).toDouble() /
                  (currency['price'] as double);
            }
          } else {
            // If no SP price, try to find any other currency with price
            for (var otherPrice in item['prices']) {
              if (otherPrice['price'] is num &&
                  (otherPrice['price'] as num) > 0) {
                final otherCurrency = currencies.firstWhere(
                  (c) => c['id'] == otherPrice['currency_id'],
                );

                if (currency['id'] == spCurrency['id']) {
                  // Converting to SP
                  finalPrice =
                      (otherPrice['price'] as num).toDouble() *
                      (otherCurrency['price'] as double);
                } else {
                  // Converting between non-SP currencies
                  final spValue =
                      (otherPrice['price'] as num).toDouble() *
                      (otherCurrency['price'] as double);
                  finalPrice = spValue / (currency['price'] as double);
                }
                break;
              }
            }
          }
        }

        await txn.insert('item_prices', {
          'item_id': id,
          'currency_id': price['currency_id'],
          'price': finalPrice,
        });
      }
    });

    return id;
  }

  Future<int> deleteItem(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getItemById(int id) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final item = results.first;
    final prices = await db.rawQuery(
      '''
      SELECT ip.*, c.code, c.symbol
      FROM item_prices ip
      JOIN currencies c ON ip.currency_id = c.id
      WHERE ip.item_id = ?
    ''',
      [id],
    );

    item['prices'] = prices;
    return item;
  }
}
