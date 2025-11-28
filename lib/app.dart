import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'providers/theme_provider.dart';

/// 앱의 루트 위젯
class YozumTicketApp extends StatelessWidget {
  const YozumTicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: '요즘티켓',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: themeProvider.themeData,
          );
        },
      ),
    );
  }
}
