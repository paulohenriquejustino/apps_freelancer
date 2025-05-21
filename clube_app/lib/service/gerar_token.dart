import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

class TokenManager {
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;
  
  TokenManager({
    FirebaseMessaging? firebaseMessaging,
    FirebaseFirestore? firestore,
  }) : 
    _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
    _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> initializeToken({String? userId}) async {
    try {
      if (Firebase.apps.isEmpty) {
        print('Firebase não está inicializado');
        return;
      }

      // Configurações de notificação
      await _configureNotificationSettings();
      
      // Obter e salvar token
      await _handleTokenRefresh(userId);
      
      // Configurar listeners
      _setUpTokenListeners(userId);
      
    } catch (e) {
      print('Erro ao inicializar token: $e');
    }
  }

  Future<void> _configureNotificationSettings() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: Platform.isIOS, // Permissão provisional para iOS
    );
    
    // Configurações específicas de plataforma
    if (Platform.isAndroid) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _handleTokenRefresh([String? userId]) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('Token obtido: $token');
      await saveTokenToFirestore(token, userId);
      await manageTopics(userId);
    }
  }

  void _setUpTokenListeners(String? userId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('Token atualizado: $newToken');
      await saveTokenToFirestore(newToken, userId);
      await manageTopics(userId);
    });
  }

  Future<void> saveTokenToFirestore(String token, [String? userId]) async {
    try {
    
      await _firestore.collection('device_tokens').doc(token).set({
        'token': token,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'lastActive': FieldValue.serverTimestamp(),
        'isActive': true,
        'topics': FieldValue.arrayUnion(['all']),
      }, SetOptions(merge: true));
      
      print('Token salvo/atualizado no Firestore: $token');
    } catch (e) {
      print('Erro ao salvar token no Firestore: $e');
    }
  }

  Future<void> manageTopics(String? userId) async {
    try {
      final currentToken = await _firebaseMessaging.getToken();
      if (currentToken == null) return;
      
      // Tópicos desejados
      final desiredTopics = {'all'};
      if (userId != null) desiredTopics.add('user_$userId');
      
      // Obter tópicos atuais
      final doc = await _firestore.collection('device_tokens').doc(currentToken).get();
      final currentTopics = Set<String>.from(doc.data()?['topics'] ?? []);
      
      // Tópicos para adicionar/remover
      final toAdd = desiredTopics.difference(currentTopics);
      final toRemove = currentTopics.difference(desiredTopics);
      
      // Atualizar assinaturas
      await Future.wait([
        ...toAdd.map((topic) => _firebaseMessaging.subscribeToTopic(topic)),
        ...toRemove.map((topic) => _firebaseMessaging.unsubscribeFromTopic(topic)),
      ]);
      
      // Atualizar no Firestore
      await doc.reference.update({
        'topics': desiredTopics.toList(),
        'lastActive': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      print('Erro ao gerenciar tópicos: $e');
    }
  }

  Future<void> removeToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        // Remover de todos os tópicos primeiro
        final doc = await _firestore.collection('device_tokens').doc(token).get();
        final topics = List<String>.from(doc.data()?['topics'] ?? []);
        
        await Future.wait(
          topics.map((topic) => _firebaseMessaging.unsubscribeFromTopic(topic))
        );
        
        // Remover do Firestore
        await doc.reference.delete();
        
        // Apagar o token
        await _firebaseMessaging.deleteToken();
        
        print('Token removido com sucesso: $token');
      }
    } catch (e) {
      print('Erro ao remover token: $e');
    }
  }
}