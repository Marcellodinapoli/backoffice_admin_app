// -----------------------------------------------------------------------------
// CONFIG / BOOTSTRAP
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializzazione Firebase (usa google-services.json su Android)
  await Firebase.initializeApp();

  runApp(const BackOfficeAdminApp());
}
