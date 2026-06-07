import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'utils/bk_local_storage_mobile.dart' as storage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  await storage.bkLocalStorageInit();

  runApp(const BackOfficeAdminApp());
}
