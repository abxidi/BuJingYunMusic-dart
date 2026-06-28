import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_providers.dart';
import 'app/bujingyun_music_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final audioHandler = await initAudioHandler();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const BujingyunMusicApp(),
    ),
  );
}
