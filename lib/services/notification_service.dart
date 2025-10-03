import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

// Manejador de mensajes en segundo plano (debe estar fuera de la clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensaje en segundo plano: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    // Solicitar permisos
    await _requestPermissions();
    
    // Configurar notificaciones locales
    await _initializeLocalNotifications();
    
    // Obtener el token FCM
    await _getAndSaveFCMToken();
    
    // Configurar manejadores de mensajes
    _setupMessageHandlers();
    
    // Manejador de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Solicitar permisos de notificaciones
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Estado de permisos: ${settings.authorizationStatus}');
  }

  // Inicializar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar cuando el usuario toca la notificación
        _handleNotificationTap(details.payload);
      },
    );

    // Crear canal de notificación para Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  // Crear canal de notificación (Android)
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Canal para notificaciones importantes de ControlaSchool',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Obtener y guardar el token FCM
  Future<void> _getAndSaveFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('Token FCM: $_fcmToken');

      if (_fcmToken != null && _auth.currentUser != null) {
        // Guardar token en Firestore
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Escuchar actualizaciones del token
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveFCMToken(newToken);
        });
      }
    } catch (e) {
      print('Error al obtener token FCM: $e');
    }
  }

  // Guardar token FCM en Firestore
  Future<void> _saveFCMToken(String token) async {
    if (_auth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Configurar manejadores de mensajes
  void _setupMessageHandlers() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en primer plano: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Cuando el usuario abre la app desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación abierta: ${message.messageId}');
      _handleNotificationTap(message.data['payload']);
    });

    // Verificar si la app se abrió desde una notificación
    _checkInitialMessage();
  }

  // Verificar mensaje inicial
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App abierta desde notificación: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage.data['payload']);
    }
  }

  // Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Notificaciones Importantes',
        channelDescription: 'Canal para notificaciones importantes de ControlaSchool',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data['payload'],
      );
    }
  }

  // Manejar cuando se toca una notificación
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      print('Payload de notificación: $payload');
      // Aquí puedes navegar a la pantalla correspondiente
      // Por ejemplo, si el payload contiene un classId, navegar a esa clase
    }
  }

  // Enviar notificación push a un usuario específico
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Obtener el token FCM del usuario
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        // Guardar en la colección de notificaciones pendientes
        // Cloud Functions enviará la notificación
        await _firestore.collection('notifications_queue').add({
          'userId': userId,
          'fcmToken': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
          'createdAt': FieldValue.serverTimestamp(),
          'sent': false,
        });
      }
    } catch (e) {
      print('Error al enviar notificación: $e');
    }
  }

  // Enviar notificación a múltiples usuarios
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final batch = _firestore.batch();
    
    for (String userId in userIds) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final fcmToken = userDoc.data()?['fcmToken'] as String?;

        if (fcmToken != null) {
          final docRef = _firestore.collection('notifications_queue').doc();
          batch.set(docRef, {
            'userId': userId,
            'fcmToken': fcmToken,
            'title': title,
            'body': body,
            'data': data ?? {},
            'createdAt': FieldValue.serverTimestamp(),
            'sent': false,
          });
        }
      } catch (e) {
        print('Error al preparar notificación para $userId: $e');
      }
    }

    await batch.commit();
  }

  // Suscribirse a un topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Suscrito al topic: $topic');
  }

  // Desuscribirse de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Desuscrito del topic: $topic');
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Limpiar recursos
  void dispose() {
    // Limpiar si es necesario
  }
}