import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Richiesta permessi (necessario su iOS, sicuro anche su Android)
    await _messaging.requestPermission();

    // Token FCM (utile per debug)
    final token = await _messaging.getToken();
    print("FCM Token: $token");

    // Notifica ricevuta in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        "🔔 Notifica foreground: ${message.notification?.title}",
      );
    });

    // Notifica cliccata
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
        "📲 Notifica aperta: ${message.notification?.title}",
      );
    });
  }
}
