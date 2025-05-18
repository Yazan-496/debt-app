import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'my_drawer.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackgroundImage;
  final bool showFooter;
  final bool showBackButton;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBackgroundImage = false,
    this.showFooter = true,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.currentLanguage == 'ar';
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isHomePage = currentRoute == '/';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          leading: Builder(
            builder:
                (context) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
          ),
          title: Align(
            alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(title),
          ),
          actions: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => Navigator.pop(context),
              ),
            ...?actions,
          ],
        ),
        drawer: const MyDrawer(),
        body: Stack(
          children: [
            if (showBackgroundImage)
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    const Color.fromARGB(
                      255,
                      255,
                      255,
                      255,
                    ).withValues(alpha: 25),
                    BlendMode.darken,
                  ),
                  child: Image.asset(
                    'assets/images/logo-aiham.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: body),
                  if (showFooter && isHomePage)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              243,
                              242,
                              242,
                            ).withValues(alpha: 30),
                            blurRadius: 10,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '© 2024 ${languageProvider.translate('common.app_name')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            languageProvider.translate('common.footer_text'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
