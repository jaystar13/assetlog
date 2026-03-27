import 'package:flutter/material.dart';
import 'design_system/theme/app_theme.dart';
import 'router/app_router.dart';

class AssetLogApp extends StatelessWidget {
  const AssetLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Asset Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
