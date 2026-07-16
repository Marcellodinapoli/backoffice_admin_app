import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:credit_calc_core/credit_calc_core.dart';

import 'app.dart';
import 'core/subscription/plan_limits_refresh.dart';
import 'firebase_options.dart';
import 'outfit/outfit_firebase.dart';
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
  await OutfitFirebase.initialize();
  await storage.bkLocalStorageInit();
  PublicPlanLimitsConfigService.start();
  await PublicPlanLimitsConfigService.ensureLoaded();
  PlanLimitsRefresh.start();

  runApp(const BackOfficeAdminApp());
}
