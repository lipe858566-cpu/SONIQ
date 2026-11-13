import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/music_repository.dart';

import 'app/soniq_app.dart';
import 'core/state/soniq_controller.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (BackendConfiguration.hasSupabase) {
    await Supabase.initialize(
      url: BackendConfiguration.supabaseUrl,
      anonKey: BackendConfiguration.supabaseAnonKey,
    );
  }
  final controller = SoniqController();
  await controller.restorePreferences();
  runApp(SoniqApp(controller: controller));
  if (BackendConfiguration.hasSupabase) {
    unawaited(controller.loadRemoteProfile());
  }
  unawaited(controller.initializeCatalog());
}
