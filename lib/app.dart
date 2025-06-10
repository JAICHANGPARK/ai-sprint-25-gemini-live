import 'package:flutter/material.dart';

import 'ui/chat_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Live Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff4896E3)),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
