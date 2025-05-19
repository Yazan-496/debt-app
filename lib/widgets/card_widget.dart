import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class CardWidget extends StatelessWidget {
  final String title;
  final String userName;
  final String item;
  final num quantity;
  final num price;
  final String currencySymbol;
  final bool isOwed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String details;

  const CardWidget({
    super.key,
    required this.title,
    required this.userName,
    required this.item,
    required this.quantity,
    required this.price,
    required this.currencySymbol,
    required this.isOwed,
    required this.onEdit,
    required this.onDelete,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = quantity * price;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    details,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${totalPrice.toStringAsFixed(0)} $currencySymbol',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOwed ? Colors.red : Colors.green,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.green,
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              languageProvider.translate('debts.name'),
              userName,
              isOwned: isOwed,
              isTotal: false,
            ),
            _buildInfoRow(
              languageProvider.translate('debts.item'),
              item,
              isOwned: isOwed,
              isTotal: false,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    languageProvider.translate('debts.quantity'),
                    quantity.toString(),
                    isOwned: isOwed,
                    isTotal: false,
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    languageProvider.translate('debts.price'),
                    '${price.toStringAsFixed(0)} $currencySymbol',
                    isOwned: isOwed,
                    isTotal: false,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              languageProvider.translate('debts.total_price'),
              '${totalPrice.toStringAsFixed(0)} $currencySymbol',
              isOwned: isOwed,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isOwned = true,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color:
                  isTotal
                      ? isOwned
                          ? Colors.red
                          : Colors.green
                      : Colors.black,
              fontSize: isTotal ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}
