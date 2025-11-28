import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/routes/app_router.dart';

/// 앱의 루트 위젯
class YozumTicketApp extends StatelessWidget {
  const YozumTicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '요즘티켓',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
    );
  }
}
