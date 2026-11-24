import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/soniq_app.dart';
import 'core/services/music_repository.dart';
import 'core/state/soniq_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.soniq.playback',
    androidNotificationChannelName: 'Reprodução do SONIQ',
    androidNotificationOngoing: true,
  );

  if (BackendConfiguration.hasSupabase) {
    await Supabase.initialize(
      url: BackendConfiguration.supabaseUrl,
      anonKey: BackendConfiguration.supabaseAnonKey,
    );
  }
  final controller = SoniqController();
  await controller.restorePreferences();
  final initialization = _initialize(controller);
  runApp(SoniqApp(controller: controller, initialization: initialization));
}

Future<void> _initialize(SoniqController controller) async {
  try {
    await controller.initializeEngine();
    if (BackendConfiguration.hasSupabase) await controller.loadRemoteProfile().timeout(const Duration(seconds: 12));
    await controller.initializeCatalog().timeout(const Duration(seconds: 12));
  } catch (error) {
    debugPrint('Inicialização: $error');
  }
}
