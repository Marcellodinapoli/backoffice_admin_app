// -----------------------------------------------------------------------------
// CONFIG / BOOTSTRAP
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'utils/bk_local_storage_mobile.dart' as storage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await storage.bkLocalStorageInit();

  runApp(const BackOfficeAdminApp());
}
