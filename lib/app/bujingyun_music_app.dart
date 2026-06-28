import 'package:flutter/material.dart';

import '../features/player/presentation/player_screen.dart';

class BujingyunMusicApp extends StatelessWidget {
  const BujingyunMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '步惊云音乐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'sans',
      ),
      home: const PlayerScreen(),
    );
  }
}
