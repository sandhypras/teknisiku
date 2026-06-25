import 'package:flutter/material.dart';

import 'theme.dart';

class SiTeknisiApp extends StatelessWidget {
  const SiTeknisiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Si Teknisi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(body: Center(child: Text('Si Teknisi'))),
    );
  }
}
