import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/debts_page.dart';
import 'screens/users_page.dart';
import 'screens/currencies_page.dart';
import 'theme/app_theme.dart';
import 'providers/language_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = LanguageProvider();
        provider.loadTranslations();
        return provider;
      },
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Debt App',
            theme: AppTheme.theme,
            locale: Locale(languageProvider.currentLanguage),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            builder: (context, child) {
              return Directionality(
                textDirection:
                    languageProvider.currentLanguage == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: child!,
                ),
              );
            },
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/': (context) => const HomePage(),
              '/settings': (context) => const SettingsPage(),
              '/debts': (context) => const DebtsPage(),
              '/users': (context) => const UsersPage(),
              '/currencies': (context) => const CurrenciesPage(),
              '/currency': (context) => const CurrenciesPage(),
            },
          );
        },
      ),
    );
  }
}
