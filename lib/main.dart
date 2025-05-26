import 'dart:async';
import 'dart:ui';
import 'package:app_web_view/firebase_options.dart';
import 'package:app_web_view/screens/splash_screen_animada.dart';
import 'package:app_web_view/service/MyFirebaseMessagingService.dart';
import 'package:app_web_view/service/api_notificacao.dart';
import 'package:app_web_view/service/gerar_token.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// URL constante movida para um arquivo de configuração seria melhor
// mas mantida aqui por simplicidade
const String initialUrl = 'https://clube.vinho24h.com.br/';

// Nome da aplicação para AppLifecycleState
const String appName = 'Vinho24h Clube';

// Configuração de cores da marca
const Color primaryColor = Color(0xFF7B1FA2); // Purple 700
const Color accentColor = Color(0xFFE1BEE7);  // Purple 100

// Função para capturar erros não tratados na aplicação
void _handleErrors() {
  // Capturar erros Flutter não tratados
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Adicione aqui logging para serviço remoto se necessário
  };

  // Capturar erros assíncronos não tratados
  PlatformDispatcher.instance.onError = (error, stack) {
    // Adicione aqui logging para serviço remoto se necessário
    debugPrint('Erro não tratado: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };
}

// Inicializa recursos necessários antes do app iniciar
Future<void> _initializeApp() async {
  // Otimização: Melhor utilizar um Future.wait para inicializações paralelas
  // quando possível para reduzir tempo de inicialização
  
  // Configurar orientação preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar estilo da UI do sistema
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar token em paralelo com outras operações
  final tokenManager = TokenManager();
  final tokenFuture = tokenManager.initializeToken();

  // Registrar handler para mensagens em background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inicializar serviço de mensagens
  await MyFirebaseMessagingService.initialize();

  // Configurar ouvintes para mensagens em foreground
  MyFirebaseMessagingService.listenForegroundMessages();

  // Aguardar a conclusão da inicialização do token
  await tokenFuture;
}

Future<void> main() async {
  // Certificar que o binding está inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar captura de erros global
  _handleErrors();

  try {
    // Inicializar recursos
    await _initializeApp();
    
    // Iniciar a aplicação
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Erro fatal ao inicializar o app: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Iniciar aplicação com modo de erro
    runApp(ErrorApp(error: e.toString()));
  }
}

// Tema da aplicação separado para reuso e consistência
class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    // Usar Material 3 para melhor design e performance
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    // Animações otimizadas para performance
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    // Otimizações para tamanho de texto
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14.0),
      bodyLarge: TextStyle(fontSize: 16.0),
      titleMedium: TextStyle(fontSize: 18.0),
      titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
    ),
  );

  // Tema escuro se precisar
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      // Usar o tema do sistema para modo claro/escuro
      themeMode: ThemeMode.system,
      // Gerenciamento de memória: não guardar histórico de rotas em memória
      themeAnimationDuration: const Duration(milliseconds: 300),
      // Inicializar diretamente a tela de Splash
      home: const SafeArea(
        // Evite wrapping com Scaffold aqui já que a SplashScreen deve ter seu próprio Scaffold
        child: AnimatedSplashScreen(),
      ),
    );
  }
}

// Widget de fallback para casos de erro fatal na inicialização
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erro - $appName',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.light,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64.0,
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Não foi possível inicializar o aplicativo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Por favor, tente reiniciar o aplicativo ou entre em contato com o suporte se o problema persistir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Reiniciar app ou fechar
                      SystemNavigator.pop();
                    },
                    child: const Text('Fechar Aplicativo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}