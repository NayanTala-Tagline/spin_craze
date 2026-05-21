import 'dart:developer';

import 'package:spin_craze/services/notification_service/local_notifications_helper.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// /// Global key for get the context
// GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// This is a Top-level function where it is used for handling background or
/// Terminated state notifications. This is optional if you don't use onBackgroundMessage stream
@pragma('vm:entry-point')
Future<dynamic> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  log('Handling a background message: ${message.messageId}');
}

/// This class is helper for initialize Notification with get permission of user,
/// To handle foreground/background/terminated state notification.
class NotificationHelper {
  /// initialize and setup the notification for device.
  static Future<void> initializeNotification() async {
    // Getting the instance of firebase messaging
    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // iniitialize local notification for foreground notification.
    await LocalNotificationHelper.localNotificationHelper.initialize();

    /// Request the notification permission to user,
    /// in Android 12 or below,by default Notification permission is granted.
    await messaging.requestPermission();

    // await messaging.getToken().then(
    //   (value) {
    //     '$value......'.logI;
    //   },
    // );

    /// To send notification to specific device, we need specific device token.
    /// To get device token, we can use following method
    // print(await messaging.getToken());

    // we can also send notification using subscibe the topic.
    // await FirebaseMessaging.instance.subscribeToTopic("myTopic");
    /// To handle Foreground notification
    FirebaseMessaging.onMessage.listen((event) {});

    /// To handle Background/terminated app notification (This is optional.)
    // FirebaseMessaging.onBackgroundMessage(
    //   _firebaseMessagingBackgroundHandler,
    // );
    // To handle the Notification Tap Event on Background.
    FirebaseMessaging.onMessageOpenedApp.listen((event) async {
      log('notification =====>>> bg: $event');
      await notificationOnTapHandler(remoteMessage: event);
    });
    // To handle the Notification Tap Event on Terminated state.
    await FirebaseMessaging.instance.getInitialMessage().then((event) async {
      log('notification =====>>> tg:  $event');
      if (event != null) {
        await notificationOnTapHandler(remoteMessage: event);
      }
    });
  }

  /// Handle on Notification tap
  static Future<void> notificationOnTapHandler({
    RemoteMessage? remoteMessage,
    NotificationResponse? localData,
    bool isLocal = false,
  }) async {
    'Notification tapped.....'.logV;
  }
}
