import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

// Função global para lidar com mensagens em background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Garante que o Firebase está inicializado
  await Firebase.initializeApp();
  
  // Inicializa as notificações locais
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Configura o canal de notificação
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações Importantes',
    description: 'Canal para notificações importantes',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Mostra a notificação
  if (message.notification != null) {
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          icon: '@drawable/ic_notification',
          styleInformation: BigPictureStyleInformation(
            DrawableResourceAndroidBitmap('@drawable/ic_notification'),
            largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_notification'),
            contentTitle: message.notification?.title,
            htmlFormatContentTitle: true,
            summaryText: message.notification?.body,
            htmlFormatSummaryText: true,
          ),
          fullScreenIntent: true,
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_notification'),
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      ),
    );
  }
}

class FirebaseApiNotificacao {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações Importantes',
    description: 'Canal para notificações importantes',
    importance: Importance.high,
  );

  Future<void> inicializar() async {
    try {
      // Inicializa as notificações locais primeiro
      await _configurarNotificacoesLocais();
      
      // Solicita permissões
      await solicitarPermissao();
      
      // Configura os handlers
      await _configurarHandlers();
      
      // Verifica se o app foi aberto por uma notificação
      await _verificarNotificacaoInicial();
    } catch (e) {
      print('Erro na inicialização das notificações: $e');
    }
  }

  Future<void> _configurarNotificacoesLocais() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Tratar interação com notificação local
        print('Notificação local interagida: ${details.payload}');
      },
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> solicitarPermissao() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
        carPlay: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await _firebaseMessaging.getToken();
        print("FCM Token: $token");
      }
    } catch (e) {
      print('Erro ao solicitar permissão: $e');
    }
  }

  Future<void> _verificarNotificacaoInicial() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _mostrarNotificacaoLocal(initialMessage);
    }
  }

  Future<void> _configurarHandlers() async {
    // Foreground
    FirebaseMessaging.onMessage.listen((message) {
      print('Recebida mensagem em foreground');
      _mostrarNotificacaoLocal(message);
    });

    // Quando o app está em background mas não terminado
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('App aberto por notificação em background');
      _mostrarNotificacaoLocal(message);
    });
  }

  Future<void> _mostrarNotificacaoLocal(RemoteMessage message) async {
    if (message.notification == null) return;

    try {
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@drawable/ic_notification',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    } catch (e) {
      print('Erro ao mostrar notificação local: $e');
    }
  }
}
