import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/shared_archives_provider.dart';

/// 앱의 루트 위젯
class YozumTicketApp extends StatelessWidget {
  const YozumTicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SharedArchivesProvider()),
      ],
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
