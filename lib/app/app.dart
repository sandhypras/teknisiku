import 'package:flutter/material.dart';

import '../features/guest/home_page.dart';
import 'theme.dart';

class SiTeknisiApp extends StatelessWidget {
  const SiTeknisiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Si Teknisi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const GuestHomePage(),
    );
  }
}
