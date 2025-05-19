import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/base_screen.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'backup_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showLanguageDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(languageProvider.translate('settings.language')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(languageProvider.translate('languages.english')),
                  onTap: () {
                    languageProvider.changeLanguage('en');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(languageProvider.translate('languages.arabic')),
                  onTap: () {
                    languageProvider.changeLanguage('ar');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return BaseScreen(
      title: languageProvider.translate('settings.title'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageProvider.translate('settings.app_settings'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.language,
                    title: languageProvider.translate('settings.language'),
                    subtitle: languageProvider.translate(
                      'settings.language_subtitle',
                    ),
                    onTap: () => _showLanguageDialog(context),
                  ),
                  const Divider(),
                  _buildSettingItem(
                    icon: Icons.backup,
                    title: languageProvider.translate('settings.backup'),
                    subtitle: languageProvider.translate(
                      'settings.backup_subtitle',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BackupSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: languageProvider.translate('settings.notifications'),
                    subtitle: languageProvider.translate(
                      'settings.notifications_subtitle',
                    ),
                    onTap: () {
                      // Add notification settings
                    },
                  ),
                  const Divider(),
                  _buildSettingItem(
                    icon: Icons.lock,
                    title: languageProvider.translate('settings.security'),
                    subtitle: languageProvider.translate(
                      'settings.security_subtitle',
                    ),
                    onTap: () {
                      // Add security settings
                    },
                  ),
                  const Divider(),
                  _buildSettingItem(
                    icon: Icons.palette,
                    title: languageProvider.translate('settings.theme'),
                    subtitle: languageProvider.translate(
                      'settings.theme_subtitle',
                    ),
                    onTap: () {
                      // Add theme settings
                    },
                  ),
                  const Divider(),
                  _buildSettingItem(
                    icon: Icons.info,
                    title: languageProvider.translate('settings.about'),
                    subtitle: languageProvider.translate(
                      'settings.about_subtitle',
                    ),
                    onTap: () {
                      // Add about information
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
