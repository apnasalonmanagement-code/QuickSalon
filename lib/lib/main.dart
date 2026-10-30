import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/services/push_notification_service.dart';

import 'app/app.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(quickSalonFirebaseBackgroundHandler);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey:
        SupabaseConfig.publishableKey,
  );

  runApp(
    const ApnaSalonManagementApp(),
  );

  // Start push delivery after the widget tree is mounted.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService.instance.initialize(managementMode: true);
  });
}