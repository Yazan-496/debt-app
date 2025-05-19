import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/logo.jpg'),
                ),
                const SizedBox(height: 16),
                Text(
                  languageProvider.translate('common.app_name'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: languageProvider.translate('common.home'),
            route: '/',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: languageProvider.translate('common.users'),
            route: '/users',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.inventory_2,
            title: languageProvider.translate('items.title'),
            route: '/items',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.money,
            title: languageProvider.translate('debts.title'),
            route: '/debts',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.currency_exchange,
            title: languageProvider.translate('common.currency'),
            route: '/currency',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: languageProvider.translate('common.settings'),
            route: '/settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.currentLanguage == 'ar';

    return ListTile(
      leading: isRTL ? null : Icon(icon, color: AppTheme.primaryColor),
      trailing: isRTL ? Icon(icon, color: AppTheme.primaryColor) : null,
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
      ),
      onTap: () {
        Navigator.of(context).pushReplacementNamed(route);
      },
    );
  }
}
