import 'dart:async';
import 'package:app_web_view/screens/web_view.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  // Criando controlador para animação
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Controlador com velocidade ajustavel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // Você pode definir velocidade aqui também (1.0 = normal, 2.0 = dobro, 0.5 = mais lenta)
    _controller.value = 0.0;
    _controller.animateTo(0.8, duration: Duration(seconds: 4));

    Timer(
      const Duration(seconds: 6),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WebViewScreen(),
        ),
      ),
    );

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ou a cor que quiser
      body: Center(
        child: Lottie.asset(
          animate: true,
          'assets/icon/logo_animada.json',
          controller: _controller,
          onLoaded: (composition) {
            composition.duration * 2;
            _controller.forward();
          },
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
