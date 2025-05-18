import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/base_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Debt App',
      showBackgroundImage: true,
      showBackButton: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
    );
  }
}
